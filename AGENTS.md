# AGENTS.md - Guía para LLMs

Este documento explica la estructura y funcionamiento del proyecto para que un modelo de lenguaje pueda entenderlo y operar sobre él.

## Propósito del Proyecto

Desplegar en GCP, usando Terraform, una infraestructura que distribuye tráfico HTTP entre dos servicios (principal y contingencia) mediante un Load Balancer global. La distribución se controla exclusivamente con variables de peso en `terraform.tfvars`.

## Estructura de Archivos

- `main.tf` — Configuración del provider de Google Cloud.
- `variables.tf` — Declaración de todas las variables del proyecto con validaciones.
- `terraform.tfvars` — Valores actuales de las variables. Este es el único archivo que se modifica para cambiar escenarios.
- `network.tf` — Red VPC, subred y reglas de firewall (HTTP y health checks).
- `compute.tf` — Dos VMs (e2-micro, Debian 12) con startup scripts que instalan nginx y sirven páginas HTML distintas. También define los instance groups (uno por VM).
- `loadbalancer.tf` — Load Balancer HTTP global: IP pública, health check, 2 backend services, URL map con weighted traffic splitting, HTTP proxy y forwarding rule.
- `outputs.tf` — Muestra la IP pública del Load Balancer tras el despliegue.

## Variables Clave

Las dos variables que controlan el comportamiento del sistema son:

- `traffic_weight_principal` (0-100): peso del servicio principal.
- `traffic_weight_contingencia` (0-100): peso del servicio de contingencia.

El URL Map en `loadbalancer.tf` usa estas variables en `weighted_backend_services` para distribuir las peticiones HTTP entrantes.

## Cómo Cambiar Escenarios

Solo modificar `terraform.tfvars`:

| Escenario | `traffic_weight_principal` | `traffic_weight_contingencia` |
|-----------|----------------------------|-------------------------------|
| Producción | 100 | 0 |
| Mantenimiento | 0 | 100 |
| Balance 50/50 | 50 | 50 |

Luego ejecutar `terraform apply`.

## Dependencias entre Recursos

```
VPC --> Subred --> VMs --> Instance Groups --> Backend Services --> URL Map --> HTTP Proxy --> Forwarding Rule
                                                    ^                                            |
                                              Health Check                                  IP Pública
```

## Notas para Auditoría

- El `project_id` es una variable; no está hardcodeado.
- Las VMs son independientes (aislamiento de fallos).
- Todo se despliega con `terraform apply`, sin configuración manual.
- Las páginas web se instalan automáticamente via startup scripts de las VMs.
- El Load Balancer usa `EXTERNAL_MANAGED` como esquema de balanceo.
