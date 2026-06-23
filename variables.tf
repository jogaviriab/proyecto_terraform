variable "project_id" {
  description = "ID del proyecto en Google Cloud Platform"
  type        = string
}

variable "region" {
  description = "Región de despliegue en GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona de despliegue en GCP"
  type        = string
  default     = "us-central1-a"
}

variable "traffic_weight_principal" {
  description = "Peso del tráfico dirigido al servicio principal (0-100)"
  type        = number
  default     = 100

  validation {
    condition     = var.traffic_weight_principal >= 0 && var.traffic_weight_principal <= 100
    error_message = "El peso debe estar entre 0 y 100."
  }
}

variable "traffic_weight_contingencia" {
  description = "Peso del tráfico dirigido al servicio de contingencia (0-100)"
  type        = number
  default     = 0

  validation {
    condition     = var.traffic_weight_contingencia >= 0 && var.traffic_weight_contingencia <= 100
    error_message = "El peso debe estar entre 0 y 100."
  }
}
