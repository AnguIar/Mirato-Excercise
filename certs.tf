provider "kubernetes" {
  # Configure the Kubernetes provider (use your own configuration)
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"  # Specify the full path to your kubeconfig file
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.16.3"
  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

resource "kubernetes_manifest" "self_signed_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "self-signed"
      namespace = "demo"
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
      namespace = "demo"
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
      namespace = "demo"
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
      namespace = "demo"
    }
    spec = {
      secretName = "serving-certificate"
      duration   = "8760h" # 1 year
      issuerRef = {
        name = "webhook-ca"
      }
      dnsNames = [
        "webhook-service",
        "webhook-service.demo",
        "webhook-service.demo.svc"
      ]
    }
  }
}
