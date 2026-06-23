# ============================================================
# VM - SERVICIO PRINCIPAL
# ============================================================
resource "google_compute_instance" "principal" {
  name         = "vm-principal"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    cat > /var/www/html/index.html <<'HTMLEOF'
    <!DOCTYPE html>
    <html>
    <head><title>Servicio Principal</title></head>
    <body>
      <h1>Bienvenido al Servicio Principal - Versión Producción</h1>
    </body>
    </html>
    HTMLEOF
    systemctl restart nginx
  EOF
}

# ============================================================
# VM - SERVICIO DE CONTINGENCIA
# ============================================================
resource "google_compute_instance" "contingencia" {
  name         = "vm-contingencia"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    cat > /var/www/html/index.html <<'HTMLEOF'
    <!DOCTYPE html>
    <html>
    <head><title>Mantenimiento</title></head>
    <body>
      <h1>Error 503 - Sitio en Mantenimiento Programado</h1>
    </body>
    </html>
    HTMLEOF
    systemctl restart nginx
  EOF
}

# ============================================================
# INSTANCE GROUPS (no administrados, 1 VM por grupo)
# ============================================================
resource "google_compute_instance_group" "principal" {
  name      = "ig-principal"
  zone      = var.zone
  instances = [google_compute_instance.principal.id]

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_instance_group" "contingencia" {
  name      = "ig-contingencia"
  zone      = var.zone
  instances = [google_compute_instance.contingencia.id]

  named_port {
    name = "http"
    port = 80
  }
}
