import json
import os
import random
import time
import uuid
from datetime import datetime

from azure.iot.device import IoTHubDeviceClient

# Load connection string from environment variable (never hardcode secrets)
CONNECTION_STRING = os.getenv("IOTHUB_DEVICE_CONNECTION_STRING")

if not CONNECTION_STRING:
    raise ValueError(
        "Missing environment variable: IOTHUB_DEVICE_CONNECTION_STRING\n"
        "Set it before running this script."
    )

STATUSES = ["moving", "idle", "maintenance", "stopped"]


def generate_telemetry():
    status = random.choice(STATUSES)

    if status == "moving":
        speed_kmh = random.randint(40, 90)
        engine_temp_c = random.randint(85, 105)
    elif status in ("idle", "stopped"):
        speed_kmh = 0
        engine_temp_c = random.randint(70, 85)
    else:  # maintenance
        speed_kmh = 0
        engine_temp_c = random.randint(20, 40)

    return {
        "event_id": str(uuid.uuid4()),
        "device_id": "TRUCK-001",
        "timestamp": datetime.now().isoformat(),
        "latitude": round(random.uniform(-34.60, -34.50), 6),
        "longitude": round(random.uniform(-58.50, -58.30), 6),
        "speed_kmh": speed_kmh,
        "engine_temp_c": engine_temp_c,
        "battery_pct": random.randint(60, 100),
        "status": status,
    }


def main():
    client = IoTHubDeviceClient.create_from_connection_string(CONNECTION_STRING)
    print("Connected to IoT Hub. Sending clean telemetry every 2 seconds...")
    print("Press Ctrl+C to stop.\n")

    try:
        while True:
            telemetry = generate_telemetry()
            message = json.dumps(telemetry)
            client.send_message(message)
            print(f"Sent: {message}")
            time.sleep(2)
    except KeyboardInterrupt:
        print("\nStopped by user.")
    finally:
        client.shutdown()
        print("Client shut down.")


if __name__ == "__main__":
    main() 