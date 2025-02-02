resource "kubernetes_mutating_webhook_configuration" "mutating_webhook" {
  metadata {
    name      = "mutating-webhook"
    annotations = {
      "cert-manager.io/inject-ca-from" = "example1/serving-certificate"
    }
    labels = {
      app = "webhook"
    }
  }

  webhook {
    name = "mutate-pods-deployments.example.com"

    client_config {
      service {
        name      = "webhook-service"
        namespace = "example1"
        path      = "/mutate"
        port      = 8080
      }
    }

    rule {
      operations = ["CREATE"]
      api_groups = [""]
      api_versions = ["v1"]
      resources = ["pods"]
    }

    rule {
      operations = ["CREATE"]
      api_groups = ["apps"]
      api_versions = ["v1"]
      resources = ["deployments"]
    }

    admission_review_versions = ["v1"]
    side_effects = "None"
  }

  depends_on = [
    kubernetes_deployment.webhook_deployment
  ]
}
