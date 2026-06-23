# ============================================================
# CONFIGURACIÓN DEL PROYECTO
# ============================================================
project_id = "proyecto-terraform-500301"
region     = "us-central1"
zone       = "us-central1-a"

# ============================================================
# CONTROL DE TRÁFICO
# Modifica estos valores para cambiar entre escenarios:
#
# Escenario 1 (Producción Activa):    principal = 100, contingencia = 0
# Escenario 2 (Mantenimiento Total):  principal = 0,   contingencia = 100
# Escenario 3 (Balance 50/50):        principal = 50,  contingencia = 50
# ============================================================
traffic_weight_principal    = 50
traffic_weight_contingencia = 50
