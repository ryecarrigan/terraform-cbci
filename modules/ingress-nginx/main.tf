resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "ingress_nginx" {
  chart      = "ingress-nginx"
  name       = "ingress-nginx"
  namespace  = var.namespace
  repository = "https://kubernetes.github.io/ingress-nginx"
  values     = [local.values]
}

locals {
  values = <<EOT
controller:
  config:
    http-snippet: |
      server {
        listen 8080 proxy_protocol;
        return 308 https://$host$request_uri;
      }
    use-proxy-protocol: "true"
  ingressClass: "nginx"
  service:
    externalTrafficPolicy: "Local"
    targetPorts:
      http: 8080
      https: "http"
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
      service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "${var.acm_certificate_arn}"
      service.beta.kubernetes.io/aws-load-balancer-ssl-negotiation-policy: "ELBSecurityPolicy-TLS-1-2-2017-01"
      service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    loadBalancerSourceRanges: ${join(",", var.load_balancer_source_ranges)}
defaultBackend:
  enabled: true
EOT
}
