#!/bin/bash

# Update and upgrade existing packages
sudo apt update -y
sudo apt upgrade -y

# Install necessary packages
sudo apt install -y python3 python3-pip python3-systemd ufw unattended-upgrades libgpiod2 squashfs-tools

# Upgrade setuptools
sudo pip3 install --upgrade setuptools

# Install Python sensor libraries
sudo pip3 install adafruit-circuitpython-shtc3 adafruit-circuitpython-dht Adafruit_DHT prometheus-client --break-system-packages

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

import logging
import time

import Adafruit_DHT

from prometheus_client import Gauge, start_http_server
from systemd.journal import JournalHandler

# Setup logging to the Systemd Journal
log = logging.getLogger('dht22_sensor')
log.addHandler(JournalHandler())
log.setLevel(logging.INFO)

# Initialize the DHT11 sensor
# Read data from GPIO4 pin on the Raspberry Pi
SENSOR = Adafruit_DHT.DHT22
SENSOR_PIN = 17

# The time in seconds between sensor reads
READ_INTERVAL = 60

# Create Prometheus gauges for humidity and temperature in
# Celsius and Fahrenheit
gh = Gauge('DO_Server_humidity_percent',
           'Humidity percentage measured by the DHT22 Sensor')
gt = Gauge('DO_Server_temperature',
           'Temperature measured by the DHT22 Sensor', ['scale'])

# Initialize the labels for the temperature scale
gt.labels('celsius')
gt.labels('fahrenheit')

def celsius_to_fahrenheit(degrees_celsius):
        return (degrees_celsius * 9/5) + 32

def read_sensor():
    try:
        humidity, temperature = Adafruit_DHT.read_retry(SENSOR, SENSOR_PIN)
    except RuntimeError as e:
        # GPIO access may require sudo permissions
        # Other RuntimeError exceptions may occur, but
        # are common.  Just try again.
        log.error("RuntimeError: {}".format(e))

    if humidity is not None and temperature is not None:
        gh.set(humidity)
        gt.labels('celsius').set(temperature)
        gt.labels('fahrenheit').set(celsius_to_fahrenheit(temperature))

        log.info("Temp:{0:0.1f}*C, Humidity: {1:0.1f}%".format(temperature, humidity))

    time.sleep(READ_INTERVAL)

if __name__ == "__main__":
    # Expose metrics
    metrics_port = 8000
    start_http_server(metrics_port)
    print("Serving sensor metrics on :{}".format(metrics_port))
    log.info("Serving sensor metrics on :{}".format(metrics_port))

    while True:
        read_sensor()



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
