# temp_pi
for raspberry pi's and temp sensors

These two scripts work for the DHT22, 11, and SHCT3 modules.
Double check the GPIO Pin number and edit the DHT model you are using in the script at
````
/opt/sensor-metrics/sensor.py
````

Steps:
where <temp_script> is either the DHT or the SHCT3 script
````
cd /temp_pi
chmod +x <temp_script>
sudo <temp_script>
````
It should do its thing and let you know the ip address to check that its running

