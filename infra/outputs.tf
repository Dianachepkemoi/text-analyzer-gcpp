output "service_uri" {
  description = "Cloud Run service URI (note: may require authenticated token to access)"
  value       = google_cloud_run_v2_service.service.uri
}
