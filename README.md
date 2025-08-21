# Insight-Agent on Google Cloud (Serverless, Terraform, CI/CD)

A minimal FastAPI service deployed as a **private Cloud Run** API, fully provisioned with **Terraform** and continuously delivered via **GitHub Actions** using **Workload Identity Federation** (no long‑lived secrets).

---

## ✨ What’s Included
- **FastAPI** app exposing `POST /analyze` to count words & characters
- **Dockerfile** (non-root user, slim base image, port 8080)
- **Terraform** to create:
  - Required APIs
  - **Artifact Registry** (Docker)
  - **Cloud Run** service (private; no public access)
  - **Runtime Service Account** with least-privilege roles
- **GitHub Actions** pipeline:
  - Test → Build → Push (Artifact Registry) → Terraform Apply (deploy new image)
- Unit tests (`pytest`) and health endpoint

---

## 🏗️ Architecture Overview

```
Developer Push to main
        │
        ▼
GitHub Actions (OIDC → GCP)
  - Test (pytest)
  - Build Docker
  - Push to Artifact Registry
  - Terraform Apply (update Cloud Run image)
        │
        ▼
Artifact Registry  ──► Cloud Run (private, IAM‑guarded) ──► FastAPI app
```

**Key Services:** Cloud Run, Artifact Registry, IAM, Cloud Build API (for docker auth), Terraform

---

## 🔐 Security & Access
- **No public access**: the service does **not** grant `roles/run.invoker` to `allUsers`.
- **Ingress** defaults to `INGRESS_TRAFFIC_INTERNAL_ONLY`. For local testing you may set `ingress = "INGRESS_TRAFFIC_ALL"` in Terraform and keep IAM‑based restriction.
- **Least privilege** runtime SA:
  - `roles/logging.logWriter`, `roles/monitoring.metricWriter`, `roles/artifactregistry.reader`.
- **CI Auth**: GitHub → Google via **Workload Identity Federation** (OIDC). No JSON keys.

---

## 🧠 Design Decisions
- **Cloud Run**: fully managed, scales to zero, per‑request autoscaling, simple container interface.
- **FastAPI**: fast, typed models, easy validation; production via `uvicorn`.
- **Artifact Registry**: regional image storage with fine‑grained IAM.
- **Terraform**: deterministic infra, repeatable deploys, simple variable‑driven flow.
- **Private by default**: IAM‑only invocation + `INGRESS_TRAFFIC_INTERNAL_ONLY` for defense‑in‑depth.
- **Image tags**: use commit SHA to produce immutable, reproducible deployments.

---

## 🚀 Run Locally (optional)
```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
# Test
curl -X POST http://localhost:8080/analyze -H "content-type: application/json" -d '{"text":"I love cloud engineering!"}'
```

---

## ☁️ Deploy on GCP (from scratch)

### 0) Prerequisites
- A GCP **project ID** and owner/editor access (or adapt for limited roles).
- **Artifact Registry** & **Cloud Run** allowed in your org.
- **Terraform** ≥ 1.6 & **gcloud** installed locally (for bootstrap) or use the provided GitHub Actions.

> Note: This sample **parameterizes the project** via `var.project_id`. Creating a brand‑new project also requires org & billing permissions; you can extend this config to add `google_project` if you have those.

### 1) Bootstrap Workload Identity Federation (one-time)
Create a service account for CI deploys and grant minimum roles:

```bash
PROJECT_ID="your-project-id"
REGION="us-central1"
SA_NAME="gh-ci-deployer"

gcloud iam service-accounts create ${SA_NAME}   --project=${PROJECT_ID}   --display-name="GitHub Actions Deployer"

# Minimum roles for deploying Cloud Run + Artifact Registry + viewing/terraform apply
gcloud projects add-iam-policy-binding ${PROJECT_ID}   --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"   --role="roles/run.admin"
gcloud projects add-iam-policy-binding ${PROJECT_ID}   --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"   --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding ${PROJECT_ID}   --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"   --role="roles/artifactregistry.admin"
gcloud projects add-iam-policy-binding ${PROJECT_ID}   --member="serviceAccount:${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"   --role="roles/compute.networkViewer"
```

Create a **Workload Identity Pool & Provider** for your GitHub org/repo and bind it to the SA (follow Google’s official guide). Then store these as repository secrets:
- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT` (e.g., `gh-ci-deployer@PROJECT_ID.iam.gserviceaccount.com`)
- `GCP_PROJECT_ID`, `GAR_LOCATION` (region), `ARTIFACT_REPO` (e.g., `insight-agent-repo`).

### 2) Prepare Terraform
```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# set project_id, region, repository_id (optional), service_name (optional)
terraform init
terraform validate
```

### 3) First Deploy (local or via CI)
**CI (recommended):** Push to `main` and let GitHub Actions build & deploy.

**Local (optional):**
```bash
# Build & push image
REGION="us-central1"
PROJECT_ID="your-project-id"
REPO="insight-agent-repo"
IMG="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO}/insight-agent:dev"

gcloud auth configure-docker ${REGION}-docker.pkg.dev
docker build -t "$IMG" .
docker push "$IMG"

# Apply Terraform with image
cd infra
terraform apply -var="project_id=${PROJECT_ID}" -var="region=${REGION}" -var="image=${IMG}" -auto-approve
```

### 4) Access the Private Service
Grant an invoker identity in `terraform.tfvars` under `invoker_members` (e.g., a service account). Use an identity token to call the service:
```bash
SERVICE_URL=$(terraform output -raw service_uri)

# Example: use gcloud to fetch an identity token and call the endpoint
ID_TOKEN=$(gcloud auth print-identity-token)
curl -X POST "${SERVICE_URL}/analyze"   -H "Authorization: Bearer ${ID_TOKEN}"   -H "Content-Type: application/json"   -d '{"text":"Hello from Cloud Run!"}'
```

---

## 📁 Repo Layout
```
.
├── app/
│   └── main.py
├── infra/
│   ├── providers.tf
│   ├── variables.tf
│   ├── services.tf
│   ├── artifact-registry.tf
│   ├── iam.tf
│   ├── run.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── tests/
│   └── test_app.py
├── .github/workflows/deploy.yml
├── Dockerfile
├── .dockerignore
├── requirements.txt
├── requirements-dev.txt
├── pyproject.toml
├── .gitignore
└── README.md
```

---

## ✅ API Contract
- `POST /analyze`
  - **Request:** `{"text": "some string"}`
  - **Response:** `{"original_text": "...", "word_count": 3, "character_count": 17}`
- `GET /healthz` → `{"status":"ok"}`

---

## 🧩 Notes & Extensions
- Swap FastAPI ↔ Flask with minimal changes.
- Add Secret Manager if you introduce secrets.
- Switch ingress to `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER` and add an internal HTTP(S) LB if you need VPC‑only access surfaces.
- Add more tests and a linter (e.g., ruff) for stricter CI gates.
