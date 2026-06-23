# ============================================================
# IP PÚBLICA ESTÁTICA
# ============================================================
resource "google_compute_global_address" "lb_ip" {
  name       = "lb-ip-publica"
  depends_on = [google_project_service.compute]
}

# ============================================================
# HEALTH CHECK
# ============================================================
resource "google_compute_health_check" "http" {
  name               = "health-check-http"
  check_interval_sec = 10
  timeout_sec        = 5
  depends_on         = [google_project_service.compute]

  http_health_check {
    port = 80
  }
}

# ============================================================
# BACKEND SERVICES
# ============================================================
resource "google_compute_backend_service" "principal" {
  name                  = "backend-principal"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.http.id]

  backend {
    group           = google_compute_instance_group.principal.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_backend_service" "contingencia" {
  name                  = "backend-contingencia"
  protocol              = "HTTP"
  port_name             = "http"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  health_checks         = [google_compute_health_check.http.id]

  backend {
    group           = google_compute_instance_group.contingencia.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# ============================================================
# URL MAP - Distribución de tráfico por pesos
# ============================================================
resource "google_compute_url_map" "lb" {
  name            = "lb-url-map"
  default_service = google_compute_backend_service.principal.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.principal.id

    route_rules {
      priority = 1

      match_rules {
        prefix_match = "/"
      }

      route_action {
        weighted_backend_services {
          backend_service = google_compute_backend_service.principal.id
          weight          = var.traffic_weight_principal
        }
        weighted_backend_services {
          backend_service = google_compute_backend_service.contingencia.id
          weight          = var.traffic_weight_contingencia
        }
      }
    }
  }
}

# ============================================================
# TARGET HTTP PROXY
# ============================================================
resource "google_compute_target_http_proxy" "lb" {
  name    = "lb-http-proxy"
  url_map = google_compute_url_map.lb.id
}

# ============================================================
# FORWARDING RULE (punto de entrada)
# ============================================================
resource "google_compute_global_forwarding_rule" "lb" {
  name                  = "lb-forwarding-rule"
  target                = google_compute_target_http_proxy.lb.id
  ip_address            = google_compute_global_address.lb_ip.id
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
}
