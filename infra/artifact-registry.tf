# Artifact Registry (Docker)
resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Container images for Insight-Agent"
  depends_on    = [google_project_service.enabled]
}
