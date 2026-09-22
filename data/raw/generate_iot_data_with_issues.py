import csv
import random
import uuid
from datetime import datetime, timedelta

# Configuración
NUM_ROWS = 10000
OUTPUT_FILE = "raw_telemetry_dirty.csv"
DEVICES = [f"TRUCK-{str(i).zfill(3)}" for i in range(1, 51)]
STATUSES = ["moving", "idle", "maintenance", "stopped"]

# Probabilidades de "suciedad"
DUPLICATE_PROB = 0.02  # 2% de chance de duplicado
INVALID_SPEED_PROB = 0.03  # 3% de velocidad imposible
INVALID_TEMP_PROB = 0.02  # 2% de temperatura imposible
NULL_DEVICE_PROB = 0.01  # 1% de device_id nulo

print(f"Generando {NUM_ROWS} registros de telemetría CON datos sucios...")

rows_to_write = []
base_time = datetime(2024, 10, 1, 0, 0, 0)

for i in range(NUM_ROWS):
    event_id = str(uuid.uuid4())
    device_id = random.choice(DEVICES)
    
    base_time += timedelta(minutes=random.randint(1, 15))
    timestamp = base_time.strftime("%Y-%m-%d %H:%M:%S")
    
    latitude = round(random.uniform(-34.60, -34.50), 6)
    longitude = round(random.uniform(-58.50, -58.30), 6)
    
    status = random.choice(STATUSES)
    
    # Datos normales
    if status == "moving":
        speed_kmh = random.randint(40, 90)
        engine_temp_c = random.randint(85, 105)
    elif status == "idle" or status == "stopped":
        speed_kmh = 0
        engine_temp_c = random.randint(70, 85)
    else:
        speed_kmh = 0
        engine_temp_c = random.randint(20, 40)
        
    battery_pct = random.randint(60, 100)
    
    # INYECTAR "SUCIEDAD"
    
    # 1. Duplicados (copiar una fila anterior)
    if random.random() < DUPLICATE_PROB and len(rows_to_write) > 0:
        rows_to_write.append(rows_to_write[random.randint(0, len(rows_to_write)-1)])
        continue
    
    # 2. Velocidad imposible
    if random.random() < INVALID_SPEED_PROB:
        speed_kmh = random.choice([-50, 999, 500])
    
    # 3. Temperatura imposible
    if random.random() < INVALID_TEMP_PROB:
        engine_temp_c = random.choice([-100, 999, 200])
    
    # 4. Device ID nulo
    if random.random() < NULL_DEVICE_PROB:
        device_id = ""
    
    rows_to_write.append([
        event_id, device_id, timestamp, latitude, longitude, 
        speed_kmh, engine_temp_c, battery_pct, status
    ])

# Escribir al CSV
with open(OUTPUT_FILE, mode="w", newline="", encoding="utf-8") as file:
    writer = csv.writer(file)
    writer.writerow([
        "event_id", "device_id", "timestamp", "latitude", "longitude", 
        "speed_kmh", "engine_temp_c", "battery_pct", "status"
    ])
    writer.writerows(rows_to_write)

print(f"✅ ¡Listo! Archivo '{OUTPUT_FILE}' generado con {len(rows_to_write)} filas (incluyendo datos sucios).")