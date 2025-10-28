#!/usr/bin/env bash
# Check SSM connection troubleshooting helper
# Usage: ./check_ssm_connection.sh -i <instance-id> [-r <region>]
# Requires: AWS CLI v2 configured, jq

set -euo pipefail

usage() {
  cat <<EOF
Usage: $0 -i <instance-id> [-r <region>]

This script runs a set of checks to help diagnose why an EC2 instance reports
"TargetNotConnected" when starting an SSM Session.

Checks performed:
  - AWS CLI / jq availability
  - Instance exists and state
  - Instance metadata: private/public IP, subnet, vpc, IAM role
  - SSM registration (describe-instance-information)
  - If not registered, attempt to send a diagnostic command (may fail)
  - VPC interface endpoints for SSM (ssm, ssmmessages, ec2messages)
  - VPC endpoint security groups and instance security groups (inspection only)

Examples:
  $0 -i i-0123456789abcdef0
  $0 -i i-0123456789abcdef0 -r af-south-1
EOF
}

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: aws CLI not found. Install and configure aws CLI v2." >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found. Install jq to parse JSON." >&2
  exit 2
fi

REGION="$(aws configure get region || echo '')"
INSTANCE_ID=""

while getopts ":i:r:h" opt; do
  case ${opt} in
    i ) INSTANCE_ID=$OPTARG ;;
    r ) REGION=$OPTARG ;;
    h ) usage; exit 0 ;;
    \? ) echo "Invalid option: -$OPTARG"; usage; exit 1 ;;
  esac
done

if [[ -z "$INSTANCE_ID" ]]; then
  echo "ERROR: instance id required." >&2
  usage
  exit 1
fi
if [[ -z "$REGION" ]]; then
  echo "ERROR: AWS region not configured and not provided with -r." >&2
  exit 1
fi

export AWS_PAGER=""

echo "Running SSM connectivity checks for $INSTANCE_ID in $REGION"

echo "\n1) EC2 instance info"
INSTANCE_JSON=$(aws ec2 describe-instances --region "$REGION" --instance-ids "$INSTANCE_ID" --output json 2>/dev/null || true)
if [[ -z "$INSTANCE_JSON" || $(echo "$INSTANCE_JSON" | jq -r '.Reservations | length') -eq 0 ]]; then
  echo "Instance $INSTANCE_ID not found in region $REGION." >&2
  exit 3
fi

INST=$(echo "$INSTANCE_JSON" | jq -r '.Reservations[0].Instances[0]')
STATE=$(echo "$INST" | jq -r '.State.Name')
PRIVATE_IP=$(echo "$INST" | jq -r '.PrivateIpAddress // "<none>"')
PUBLIC_IP=$(echo "$INST" | jq -r '.PublicIpAddress // "<none>"')
SUBNET_ID=$(echo "$INST" | jq -r '.SubnetId // "<none>"')
VPC_ID=$(echo "$INST" | jq -r '.VpcId // "<none>"')
IAM_PROFILE=$(echo "$INST" | jq -r '.IamInstanceProfile.Arn // "<none>"')
INST_SGS=$(echo "$INST" | jq -r '[.SecurityGroups[].GroupId] | join(",")')

cat <<EOF
Instance: $INSTANCE_ID
  State: $STATE
  Private IP: $PRIVATE_IP
  Public IP: $PUBLIC_IP
  Subnet: $SUBNET_ID
  VPC: $VPC_ID
  IAM instance profile ARN: $IAM_PROFILE
  Security groups: ${INST_SGS:-<none>}
EOF

if [[ "$STATE" != "running" ]]; then
  echo "\nInstance is not running; SSM cannot connect while instance is stopped/terminated." >&2
fi

echo "\n2) SSM registration info (describe-instance-information)"
SSM_INFO=$(aws ssm describe-instance-information --region "$REGION" --filters "key=InstanceIds,value=$INSTANCE_ID" --output json 2>/dev/null || true)
SSM_COUNT=$(echo "$SSM_INFO" | jq -r '.InstanceInformationList | length')
if [[ "$SSM_COUNT" -gt 0 ]]; then
  echo "SSM reports the instance is known. Details:"
  echo "$SSM_INFO" | jq -r '.InstanceInformationList[0] | {InstanceId, PingStatus, AgentVersion, PlatformName, PlatformType, LastPingDateTime} '
  PING=$(echo "$SSM_INFO" | jq -r '.InstanceInformationList[0].PingStatus')
  if [[ "$PING" == "Online" ]]; then
    echo "\nGood: SSM PingStatus is Online — session should work (if IAM and network allow)."
  else
    echo "\nSSM PingStatus: $PING (not online) — SSM Agent may be running but not able to reach SSM endpoints."
  fi
else
  echo "SSM does not report the instance (not managed)."
  echo "Attempting to run a diagnostic send-command (this may fail if agent is not connected)..."
  CMD_ID=$(aws ssm send-command \
    --region "$REGION" \
    --instance-ids "$INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --comment "diagnostic: check amazon-ssm-agent" \
    --parameters commands='["systemctl status amazon-ssm-agent || status amazon-ssm-agent || echo \"ssm-agent-not-found\"", "echo exit:$?" ]' \
    --output json 2>/dev/null || true)
  if [[ -z "$CMD_ID" ]]; then
    echo "Send-command failed (as expected if instance isn't connected)."
  else
    echo "Send-command submitted:"
    echo "$CMD_ID" | jq -r '.Command | {CommandId, Status, DocumentName}'
    CMD=$(echo "$CMD_ID" | jq -r '.Command.CommandId')
    sleep 2
    echo "Command invocation result (if available):"
    aws ssm list-command-invocations --region "$REGION" --command-id "$CMD" --details --output json || true
  fi
fi

echo "\n3) VPC endpoints for SSM services (ssm, ssmmessages, ec2messages) in the VPC"
for svc in ssm ssmmessages ec2messages; do
  SVCSERV="com.amazonaws.$REGION.$svc"
  echo "\nChecking VPC endpoints for $SVCSERV"
  aws ec2 describe-vpc-endpoints --region "$REGION" --filters Name=service-name,Values="$SVCSERV" Name=vpc-id,Values="$VPC_ID" --output json | jq -r '.VpcEndpoints | if length==0 then "<none>" else .[] | {VpcEndpointId: .VpcEndpointId, State: .State, ServiceName: .ServiceName, SecurityGroupIds: .Groups, SubnetIds: .SubnetIds, PrivateDnsEnabled: .PrivateDnsEnabled} end'
done

echo "\n4) Security groups: instance SGs and VPC endpoint SGs (if any)"
if [[ -n "$INST_SGS" ]]; then
  echo "Instance security groups details:"
  aws ec2 describe-security-groups --region "$REGION" --group-ids $(echo $INST_SGS | sed 's/,/ /g') --output json | jq -r '.SecurityGroups[] | {GroupId, GroupName, Description, VpcId, Ingress: .IpPermissions, Egress: .IpPermissionsEgress}'
fi

# Find vpc endpoints and print their security groups
echo "\nVPC endpoints in this VPC (summary):"
aws ec2 describe-vpc-endpoints --region "$REGION" --filters Name=vpc-id,Values="$VPC_ID" --output json | jq -r '.VpcEndpoints[] | {VpcEndpointId, ServiceName, VpcEndpointType, State, SubnetIds, SecurityGroupIds}'

cat <<EOF

Hints / next steps depending on findings:
- If SSM reports the instance (PingStatus Online), but StartSession still returns TargetNotConnected:
  * Verify instance IAM role includes AmazonSSMManagedInstanceCore (we added an attachment for node role).
  * Confirm the instance is using the expected IAM instance profile (output above).
  * Confirm session manager plugin (local) is up to date: install AWS Session Manager Plugin or use AWS CLI v2 that has it built-in.

- If SSM does not report the instance:
  * Make sure the SSM agent is installed and running on the instance. For Amazon Linux 2: `sudo systemctl status amazon-ssm-agent`.
  * If instance is in private subnets, confirm VPC interface endpoints for ssm/ssmmessages/ec2messages exist (checked above).
  * Check instance outbound network rules and endpoint SGs to ensure the instance can reach the endpoint.

- To inspect logs on the instance (if you have another working access method such as SSH or existing SSM session for other instances):
  * /var/log/amazon/ssm/amazon-ssm-agent.log (Linux)

EOF

exit 0
