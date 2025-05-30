#!/bin/bash

# Check if the /var/run/reboot-required file exists
if [ -f "/var/run/reboot-required" ]; then
    echo "Reboot required. Initiating the reboot..."

    # Stop all processes managed by supervisorctl
    supervisorctl stop all

    # Initialize timer
    SECONDS=0
    TIMEOUT=1800  # 30 minutes in seconds

    # Wait until miniTruco has let all players finish their games
    while pgrep -f "java.*server.jar" >/dev/null; do
        if [ "$SECONDS" -ge "$TIMEOUT" ]; then
            echo "Timeout reached. Forcing reboot."
            break
        fi

        echo "Waiting for Java processes to stop..."
        sleep 5
    done

    # Reboot the system
    sudo reboot
else
    echo "No reboot required."
fi
