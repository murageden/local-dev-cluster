# resource "kubernetes_namespace_v1" "monitoring" {
#   metadata {
#     name = "monitoring"
#   }
# }

# resource "kubernetes_namespace_v1" "outputs" {
#   metadata {
#     name = "outputs"
#   }
# }

resource "kubernetes_namespace_v1" "applications" {
  metadata {
    name = "applications"
  }
}

resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "oci://ghcr.io/argoproj/argo-helm"
  chart      = "argo-cd"
  version    = "7.3.1"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name

  wait = false

  values = [
    yamlencode({
      global = {
        domain = "localhost"
      }
      configs = {
        params = {
          "server.insecure"            = "true"
          "server.basehttps"           = "false" # Disables structural HTTPS injection
          "server.url"                 = "http://localhost/argocd"
          "server.rootpath"            = "/argocd"
          "server.basehref"            = "/argocd"
          "server.extraArgs"           = "--insecure"
          "api.security.xsrf.enabled"  = "false"
          "api.security.secureCookies" = "false"
        }
        cm = {
          "api.security.secureCookies" = "false"
          "url"                        = "http://localhost"
        }
      }
    })
  ]
}

# values = [
#   yamlencode({
#     server = {
#       insecure = true

#       # Inject applications directly into the ArgoCD deployment lifecycle
#       additionalApplications = [
#         {
#           name      = "applications"
#           namespace = "argocd"
#           additionalLabels = {
#             "managed-by" = "terraform"
#           }
#           spec = {
#             project = "default"
#             source = {
#               repoURL        = "https://github.com/murageden/argoCD-repo"
#               targetRevision = "HEAD"
#               path           = "." # Path inside your repository containing child manifests
#             }
#             destination = {
#               server    = "https://kubernetes.default.svc"
#               namespace = "applications" # Namespace where the child manifests will be deployed
#             }
#             syncPolicy = {
#               automated = {
#                 prune    = true
#                 selfHeal = true
#               }
#               syncOptions = [
#                 "CreateNamespace=false" # Prevent ArgoCD from creating the namespace if it doesn't exist
#               ]
#             }
#           }
#         }
#       ]
#     }
#   })
# ]


# resource "helm_release" "prometheus" {
#   name            = "prometheus"
#   repository      = "https://prometheus-community.github.io/helm-charts"
#   chart           = "kube-prometheus-stack"
#   namespace       = kubernetes_namespace_v1.monitoring.metadata[0].name
#   version         = "89.2.2"
#   wait            = false
#   timeout         = 900
#   atomic          = true
#   cleanup_on_fail = true

#   set = [{
#     name  = "grafana.enabled"
#     value = "true"
#     },

#     {
#       name  = "grafana.adminPassword"
#       value = "SuperSecurePassword123"
#     },

#     {
#       name  = "grafana.service.type"
#       value = "ClusterIP"
#     },

#     {
#       name  = "alertmanager.enabled"
#       value = "false" # Disables local alert notifications
#     },
#     {
#       name  = "prometheusOperator.admissionWebhooks.enabled"
#       value = "false" # Saves webhook validation overhead locally
#     },

#     {
#       name  = "prometheusOperator.tlsProxy.enabled"
#       value = "false" # Saves webhook validation overhead locally
#     },

#     {
#       name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
#       value = "false" # Ensures that Prometheus scrapes all ServiceMonitors, including those not managed by Helm
#     },

#     {
#       name  = "prometheus.prometheusSpec.persistentVolume.enabled"
#       value = "false" # Disables persistent storage for Prometheus
#     },

#     {
#       name  = "prometheus.prometheusSpec.retention"
#       value = "7d" # Sets the retention period for Prometheus data to 7 days
#     },

#     {
#       name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
#       value = "2Gi" # Sets the storage request for Prometheus to 2Gi
#     },

#     {
#       name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
#       value = "standard" # Specifies the storage class for Prometheus
#     },

#     {
#       name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
#       value = "ReadWriteOnce" # Sets the access mode for Prometheus storage
#     },

#     {
#       name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.selector.matchLabels.app"
#       value = "prometheus" # Labels the Prometheus PVC for identification
#     },

#     {
#       name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.selector.matchLabels.component"
#       value = "server" # Labels the Prometheus PVC for identification
#   }]
# }

# resource "helm_release" "loki" {
#   name       = "loki"
#   repository = "https://grafana-community.github.io/helm-charts"
#   chart      = "loki"
#   namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
#   wait       = false

#   values = [
#     yamlencode({
#       deploymentMode = "Monolithic"

#       loki = {
#         auth_enabled = false

#         storage = {
#           type = "filesystem"
#           bucketNames = {
#             chunks = "local-chunks"
#             ruler  = "local-ruler"
#             admin  = "local-admin"
#           }
#         }

#         commonConfig = {
#           replication_factor = 1
#           path_prefix        = "/var/loki"
#         }

#         useTestSchema = true
#       }

#       chunksCache = {
#         enabled = false
#       }
#       resultsCache = {
#         enabled = false
#       }

#       singleBinary = {
#         replicas = 1
#         persistence = {
#           enabled      = true
#           size         = "2Gi"
#           storageClass = "standard"
#         }

#       }

#       backend = { replicas = 0 }
#       read    = { replicas = 0 }
#       write   = { replicas = 0 }

#       gateway = {
#         enabled = true
#       }
#     })
#   ]
# }


# resource "helm_release" "promtail" {
#   name       = "promtail"
#   repository = "https://grafana.github.io/helm-charts"
#   chart      = "promtail"
#   namespace  = kubernetes_namespace_v1.monitoring.metadata[0].name
#   wait       = false

#   values = [
#     <<-EOT
#     config:
#       clients:
#         - url: http://loki-gateway.monitoring/loki/api/v1/push
#     EOT
#   ]

#   depends_on = [helm_release.loki]
# }

# resource "helm_release" "traefik" {
#   name             = "traefik"
#   repository       = "https://helm.traefik.io/traefik"
#   version          = "41.4.0"
#   chart            = "traefik"
#   namespace        = kubernetes_namespace_v1.argocd.metadata[0].name
#   create_namespace = false
#   wait             = false

#   set = [
#     {
#       name  = "ports.web.nodePort"
#       value = "30080"
#     },
#     {
#       name  = "providers.kubernetesIngress.enabled"
#       value = "true"
#     },
#     {
#       name  = "ports.websecure.nodePort"
#       value = "30443"
#     },

#     {
#       name  = "service.type"
#       value = "ClusterIP"
#   }]

#   depends_on = [helm_release.argocd]

# }

# resource "kubernetes_ingress_v1" "ingress" {

#   metadata {
#     name      = "ingress"
#     namespace = kubernetes_namespace_v1.argocd.metadata[0].name
#     annotations = {
#       "kubernetes.io/ingress.class" = "traefik"
#     }
#   }

#   spec {
#     ingress_class_name = "traefik"
#     # ArgoCD
#     rule {
#       http {
#         path {
#           path      = "/"
#           path_type = "Prefix"
#           backend {
#             service {
#               name = "argocd-server"
#               port {
#                 number = 80
#               }
#             }
#           }
#         }
#       }
#     }

#   }
#   depends_on = [helm_release.traefik]
# }

# output "monitoring_namespace" {
#   value       = helm_release.prometheus.namespace
#   description = "The namespace where the monitoring stack is deployed."
# }
