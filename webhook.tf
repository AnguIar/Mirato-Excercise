resource "kubernetes_deployment" "webhook_deployment" {
  metadata {
    name      = "webhook-deployment"
    namespace = "example1"
    labels = {
      app = "webhook"
    }
    annotations = {
      "cert-manager.io/inject-ca-from" = "example1/webhook1-certificate"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "webhook"
      }
    }

    template {
      metadata {
        labels = {
          app = "webhook"
        }
      }

      spec {
        container {
          name  = "webhook"
          image = "10.100.102.18:31855/webhook:v1.0.0"
          image_pull_policy = "Always"

          env {
            name  = "DEFAULT_CPU_REQUEST"
            value = "500m"
          }

          env {
            name  = "DEFAULT_MEMORY_REQUEST"
            value = "512Mi"
          }

          env {
            name  = "DEFAULT_CPU_LIMIT"
            value = "1000m"
          }

          env {
            name  = "DEFAULT_MEMORY_LIMIT"
            value = "1Gi"
          }

          port {
            container_port = 8080
          }

          volume_mount {
            name      = "certs"
            mount_path = "/etc/ssl/certs"
            read_only = true
          }
        }

        volume {
          name = "certs"
          secret {
            secret_name = "serving-certificate"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "webhook_service" {
  metadata {
    name      = "webhook-service"
    namespace = "example1"
  }

  spec {
    selector = {
      app = "webhook"
    }

    port {
      port       = 8080
      target_port = 8080
    }
  }
}
