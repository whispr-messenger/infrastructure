terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
    labels = {
      name = "argocd"
    }
  }
}

resource "kubernetes_namespace" "postgresql" {
  metadata {
    name = "postgresql"
    labels = {
      name = "postgresql"
    }
  }
}

resource "kubernetes_namespace" "redis" {
  metadata {
    name = "redis"
    labels = {
      name = "redis"
    }
  }
}

resource "kubernetes_namespace" "sonarqube" {
  metadata {
    name = "sonarqube"
    labels = {
      name = "sonarqube"
    }
  }
}

resource "kubernetes_namespace" "whispr_prod" {
  metadata {
    name = "whispr-prod"
    labels = {
      name = "whispr-prod"
    }
  }
}
