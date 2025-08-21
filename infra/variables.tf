variable "project_id" {
  description = "GCP project ID to deploy into"
  type        = string
}

variable "region" {
  description = "GCP region (e.g., us-central1, europe-west1)"
  type        = string
  default     = "us-central1"
}

variable "repository_id" {
  description = "Artifact Registry repository ID"
  type        = string
  default     = "insight-agent-repo"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "insight-agent"
}

variable "image" {
  description = "Full container image reference in Artifact Registry (e.g., us-central1-docker.pkg.dev/PROJECT/REPO/insight-agent:TAG)"
  type        = string
}

variable "invoker_members" {
  description = "List of IAM members allowed to invoke the Cloud Run service (e.g., ["serviceAccount:client-sa@project.iam.gserviceaccount.com"])"
  type        = list(string)
  default     = []
}

variable "ingress" {
  description = "Ingress policy for Cloud Run. Options: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_ONLY"
}
