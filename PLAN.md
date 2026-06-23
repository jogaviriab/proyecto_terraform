# Plan del Proyecto Terraform - Servicios en la Nube 2026-01

## Objetivo

Diseñar e implementar con Terraform una infraestructura en GCP que permita distribuir el tráfico web entre un servicio principal y uno de contingencia, controlando los pesos de distribución únicamente mediante variables.

---

## Estructura de Archivos

```
proyecto_terraform/
├── main.tf              # Provider de GCP
├── variables.tf         # Declaración de variables
├── terraform.tfvars     # Valores por defecto (escenario activo)
├── network.tf           # VPC, subnet, firewall rules
├── compute.tf           # Las 2 VMs con startup scripts
├── loadbalancer.tf      # Load Balancer, backend services, URL map, forwarding rule
├── outputs.tf           # IP pública del Load Balancer
├── README.md            # Documentación y evidencias
├── AGENTS.md            # Explicación del proyecto para LLMs
└── .gitignore           # Excluir .tfstate, .terraform/, credenciales
```

---

## Variables

| Variable                      | Tipo   | Descripción                                  | Ejemplo          |
|-------------------------------|--------|----------------------------------------------|------------------|
| `project_id`                  | string | ID del proyecto en GCP                       | `"mi-proyecto"`  |
| `region`                      | string | Región de despliegue                         | `"us-central1"`  |
| `zone`                        | string | Zona de despliegue                           | `"us-central1-a"`|
| `traffic_weight_principal`    | number | Peso del servicio principal (0-100)          | `100`            |
| `traffic_weight_contingencia` | number | Peso del servicio de contingencia (0-100)    | `0`              |

### Escenarios de evaluación

| Escenario               | `traffic_weight_principal` | `traffic_weight_contingencia` |
|--------------------------|----------------------------|-------------------------------|
| 1 - Producción Activa    | 100                        | 0                             |
| 2 - Mantenimiento Total  | 0                          | 100                           |
| 3 - Balance 50/50        | 50                         | 50                            |

---

## Arquitectura

### Flujo del tráfico

```
Usuario (Internet)
       |
       v
IP Pública Estática (google_compute_global_address)
       |
       v
Global Forwarding Rule (puerto 80)
       |
       v
Target HTTP Proxy
       |
       v
URL Map (route_rules con weighted_backend_services)
       |
       +--> Backend Service Principal (peso X%) --> Instance Group A --> VM Principal
       |
       +--> Backend Service Contingencia (peso Y%) --> Instance Group B --> VM Contingencia
```

### Recursos GCP

#### Red
- `google_compute_network` — VPC personalizada (sin subredes automáticas)
- `google_compute_subnetwork` — Subred en la región seleccionada
- `google_compute_firewall` — Regla para permitir tráfico HTTP (puerto 80) y health checks de GCP

#### Cómputo
- `google_compute_instance` (principal) — VM e2-micro con Debian, startup script que instala nginx y escribe el HTML: "Bienvenido al Servicio Principal - Versión Producción"
- `google_compute_instance` (contingencia) — VM e2-micro con Debian, startup script que instala nginx y escribe el HTML: "Error 503 - Sitio en Mantenimiento Programado"

Ambas VMs son completamente independientes (aislamiento de fallos).

#### Load Balancer HTTP Global
- `google_compute_global_address` — IP pública estática reservada
- `google_compute_health_check` — Health check HTTP en puerto 80
- `google_compute_instance_group` x2 — Un grupo no administrado por cada VM
- `google_compute_backend_service` x2 — Un backend service por grupo de instancias
- `google_compute_url_map` — Usa `route_rules` con `weighted_backend_services` para distribuir el tráfico según las variables de peso
- `google_compute_target_http_proxy` — Proxy HTTP que apunta al URL Map
- `google_compute_global_forwarding_rule` — Vincula la IP pública con el proxy en puerto 80

---

## Decisiones Técnicas

| Decisión                | Elección           | Justificación                                           |
|-------------------------|--------------------|---------------------------------------------------------|
| Tipo de LB              | HTTP(S) Global     | Soporta weighted traffic splitting nativo en URL Map    |
| Tipo de máquina         | e2-micro           | Costo mínimo, elegible para free tier                   |
| Sistema operativo       | Debian 12          | Ligero, instalación rápida de nginx                     |
| Servidor web            | nginx              | Ligero, configuración simple con startup script         |
| Región por defecto      | us-central1        | Bajo costo, buena disponibilidad                        |
| Instance groups         | No administrados   | Suficiente para 1 VM por grupo, sin overhead de MIG     |
| Backend services        | 2 separados        | Requerido para asignar pesos independientes en URL Map  |

---

## Startup Scripts

### VM Principal
```bash
#!/bin/bash
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>Servicio Principal</title></head>
<body><h1>Bienvenido al Servicio Principal - Versión Producción</h1></body>
</html>
HTMLEOF
systemctl restart nginx
```

### VM Contingencia
```bash
#!/bin/bash
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html <<'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>Mantenimiento</title></head>
<body><h1>Error 503 - Sitio en Mantenimiento Programado</h1></body>
</html>
HTMLEOF
systemctl restart nginx
```

---

## Firewall

Se necesitan 2 reglas:

1. **Permitir HTTP** — Puerto 80 desde `0.0.0.0/0` (tráfico externo)
2. **Permitir Health Checks de GCP** — Puerto 80 desde los rangos de IP de los health checkers de Google:
   - `130.211.0.0/22`
   - `35.191.0.0/16`

---

## Checklist Pre-Entrega

- [ ] Código formateado con `terraform fmt`
- [ ] `terraform apply` exitoso en los 3 escenarios
- [ ] Capturas de pantalla de cada escenario
- [ ] `terraform destroy` exitoso (captura obligatoria)
- [ ] Consola GCP vacía de recursos del proyecto
- [ ] Archivo `.tfstate` eliminado o en `.gitignore`
- [ ] Profesor (`vdrestrepot@unal.edu.co`) agregado como Editor en IAM
- [ ] `project_id` parametrizado como variable
- [ ] README.md con documentación completa
- [ ] AGENTS.md con explicación para LLMs
- [ ] Repositorio público o con acceso para el profesor
- [ ] Correo enviado con asunto: `[Servicios Nube 2026-01] Proyecto Terraform - Grupo [N]`

---

## Riesgos y Mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| Dejar recursos activos y obtener 0.0 | Ejecutar `terraform destroy` y verificar en consola |
| Health checks fallan y LB no distribuye | Verificar reglas de firewall para rangos de Google |
| Weighted backends no alternan en 50/50 | Configurar `route_rules` correctamente; el LB global distribuye por peso real |
| Costos excesivos | Usar e2-micro, destruir recursos al terminar pruebas |
| Profesor no puede desplegar | Asegurar que `project_id` es variable, no hardcoded |
