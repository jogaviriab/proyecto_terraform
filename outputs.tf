output "lb_ip_address" {
  description = "IP pública del Load Balancer (punto de entrada único)"
  value       = google_compute_global_address.lb_ip.address
}

output "url_aplicacion" {
  description = "URL para acceder a la aplicación"
  value       = "http://${google_compute_global_address.lb_ip.address}"
}
