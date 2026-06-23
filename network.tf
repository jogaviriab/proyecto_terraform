# ============================================================
# VPC
# ============================================================
resource "google_compute_network" "vpc" {
  name                    = "vpc-proyecto"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.compute]
}

# ============================================================
# SUBRED
# ============================================================
resource "google_compute_subnetwork" "subnet" {
  name          = "subnet-proyecto"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc.id
}

# ============================================================
# FIREWALL - Permitir tráfico HTTP (puerto 80)
# ============================================================
resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

# ============================================================
# FIREWALL - Permitir Health Checks de GCP
# ============================================================
resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["http-server"]
}
