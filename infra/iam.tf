# Runtime service account for Cloud Run
resource "google_service_account" "run_sa" {
  project      = var.project_id
  account_id   = "${var.service_name}-sa"
  display_name = "Runtime SA for ${var.service_name}"
}

# Least-privilege roles for runtime logging/metrics and pulling images
resource "google_project_iam_member" "run_sa_logwriter" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "run_sa_metricwriter" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "run_sa_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}
