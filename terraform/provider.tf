provider "google" {
  credentials = file("${path.module}/../key.json")
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
}

resource "google_project_service" "sql_api" {
  project = var.project_id
  service = "sqladmin.googleapis.com"
}

resource "google_project_service" "cloud_resource_manager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "service_networking" {
  project = var.project_id
  service = "servicenetworking.googleapis.com"
}

resource "google_project_service" "artifact_api" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"
}
