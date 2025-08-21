resource "google_cloud_run_v2_service" "service" {
  name     = var.service_name
  location = var.region
  ingress  = var.ingress

  template {
    service_account = google_service_account.run_sa.email

    containers {
      image = var.image
      ports {
        container_port = 8080
      }
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
      # Health check
      startup_probe {
        http_get {
          path = "/healthz"
        }
        initial_delay_seconds = 2
        timeout_seconds       = 2
        period_seconds        = 10
        failure_threshold     = 3
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.enabled,
    google_artifact_registry_repository.repo
  ]
}

# Allow only specific principals to invoke (no public access)
resource "google_cloud_run_v2_service_iam_binding" "invokers" {
  project  = google_cloud_run_v2_service.service.project
  location = google_cloud_run_v2_service.service.location
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  members  = var.invoker_members

  condition {
    title       = "allow-specific-invokers"
    description = "Restrict invocation to approved identities"
    expression  = "true"
  }
}
