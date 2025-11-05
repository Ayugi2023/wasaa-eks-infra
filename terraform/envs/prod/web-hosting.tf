# Web hosting infrastructure for wasaa-web-service
module "web_hosting" {
  source = "../../modules/web-hosting"

  bucket_name         = "wasaa-web-service-hosting-${var.environment}"
  environment         = var.environment
  api_gateway_name    = "wasaa-web-api-gateway-${var.environment}"
  api_stage_name      = "prod"
  eks_alb_dns_name    = module.eks_cluster.alb_dns_name
  cloudfront_price_class = "PriceClass_100"

  depends_on = [module.eks_cluster]
}
