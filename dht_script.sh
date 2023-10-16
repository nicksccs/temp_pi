#!/bin/bash

# Update and upgrade existing packages
sudo apt update -y
sudo apt upgrade -y

# Install necessary packages
sudo apt install -y python3 python3-pip python3-systemd ufw unattended-upgrades libgpiod2 squashfs-tools prometheus-client

# Upgrade setuptools
sudo pip3 install --upgrade setuptools

# Install Python sensor libraries
sudo pip3 install adafruit-circuitpython-shtc3 adafruit-circuitpython-dht Adafruit_DHT

# Configure UFW
sudo ufw default allow outgoing
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw limit ssh
sudo ufw enable
sudo ufw allow 8000

# Configure unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades

# Create the Prometheus sensor script
cat <<EOL > /opt/sensor-metrics/sensor.py
#!/usr/bin/env python3

# ... (Your Python script content)

EOL

# Create the systemd service file
cat <<EOL > /etc/systemd/system/sensor.service
[Unit]
Description=DHT22 Sensor Metrics Service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
ExecStart=python3 /opt/sensor-metrics/sensor.py

[Install]
WantedBy=multi-user.target
EOL

# Start and enable the service
sudo mkdir /opt/sensor-metrics
sudo systemctl enable sensor.service
sudo systemctl start sensor.service

# Enable I2C in raspi-config
sudo raspi-config nonint do_i2c 0

# Get the MAC address
ifconfig | grep ether

# Finish installation
echo "Installation completed."
