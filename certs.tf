provider "kubernetes" {
  # Configure the Kubernetes provider (use your own configuration)
  config_path = "~/.kube/config"
}

resource "kubernetes_manifest" "self_signed_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "self-signed"
      namespace = "example1"
    }
    spec = {
      selfSigned = {}
    }
  }
}

resource "kubernetes_manifest" "ca_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "ca-certificate"
      namespace = "example1"
    }
    spec = {
      secretName = "ca-certificate"
      duration   = "43800h" # 5 years
      issuerRef = {
        name = "self-signed"
      }
      commonName = "ca.example-webhook.cert-manager"
      isCA       = true
    }
  }
}

resource "kubernetes_manifest" "webhook_ca_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "webhook-ca"
      namespace = "example1"
    }
    spec = {
      ca = {
        secretName = "ca-certificate"
      }
    }
  }
}

resource "kubernetes_manifest" "serving_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "serving-certificate"
      namespace = "example1"
    }
    spec = {
      secretName = "serving-certificate"
      duration   = "8760h" # 1 year
      issuerRef = {
        name = "webhook-ca"
      }
      dnsNames = [
        "webhook-service",
        "webhook-service.example1",
        "webhook-service.example1.svc"
      ]
    }
  }
}
