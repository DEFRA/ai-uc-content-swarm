#!/bin/bash
set -e

INIT_DIR="/etc/moto/init/ready.d"

echo "Starting moto_server in the background..."
moto_server -H 0.0.0.0 -p 5000 &
MOTO_PID=$!

echo "Waiting for moto_server to become healthy..."
until curl -sf http://localhost:5000/moto-api/data.json > /dev/null 2>&1; do
    echo "  moto_server not ready yet, retrying in 1s..."
    sleep 1
done
echo "moto_server is healthy."

if [ -d "$INIT_DIR" ]; then
    for script in $(find "$INIT_DIR" -maxdepth 1 -name "*.sh" -type f | sort); do
        echo "Running init script: $script"
        bash "$script"
    done
else
    echo "No init directory found at $INIT_DIR, skipping."
fi

echo "Moto Server is ready."
wait "$MOTO_PID"
