#!/bin/bash

# Ask the user for the IP address
read -p "Please enter the server IP (IPv4 or IPv6): " server_ip

# Function to validate IP address
validate_ip() {
    local ip=$1
    local valid_ipv4=$(echo $ip | grep -Eo '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
    local valid_ipv6=$(echo $ip | grep -Eo '^(?:[a-fA-F0-9]{1,4}:){7}[a-fA-F0-9]{1,4}$|^((?:[a-fA-F0-9]{1,4}:){6}|::(?:[a-fA-F0-9]{1,4}:){5}|(?:[a-fA-F0-9]{1,4})?::(?:[a-fA-F0-9]{1,4}:){4}|((?:[a-fA-F0-9]{1,4}:)?[a-fA-F0-9]{1,4})?::(?:[a-fA-F0-9]{1,4}:){3}|((?:[a-fA-F0-9]{1,4}:){0,2}[a-fA-F0-9]{1,4})?::(?:[a-fA-F0-9]{1,4}:){2}|((?:[a-fA-F0-9]{1,4}:){0,3}[a-fA-F0-9]{1,4})?::[a-fA-F0-9]{1,4}:|((?:[a-fA-F0-9]{1,4}:){0,4}[a-fA-F0-9]{1,4})?::)$|^((?:[a-fA-F0-9]{1,4}:){1,5}|::(?:[a-fA-F0-9]{1,4}:){0,4})(?:[a-fA-F0-9]{1,4})?(?:\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})?$')
    if [[ -n $valid_ipv4 || -n $valid_ipv6 ]]; then
        return 0
    else
        return 1
    fi
}

# Validate the entered IP address
if ! validate_ip $server_ip; then
    echo "Invalid IP address. Please try again."
    exit 1
fi

# Create and copy ping_script.sh
cat << EOF > /usr/local/bin/ping_script.sh
#!/bin/bash

# Function to ping IP and log the result
ping_server() {
    while true; do
        ping -c 5 $1 > /dev/null
        if [ $? -ne 0 ]; then
            echo "Server $1 is down at \$(date)" >> /var/log/server_ping.log
        fi
        sleep 60
    done
}

# Start pinging the server
ping_server $server_ip
EOF

# Make the ping script executable
chmod +x /usr/local/bin/ping_script.sh

# Create systemd service file
cat << EOF > /etc/systemd/system/ping_script.service
[Unit]
Description=Ping Script Service
After=network.target

[Service]
ExecStart=/usr/local/bin/ping_script.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl enable ping_script.service
systemctl start ping_script.service

# Display the status of the service
systemctl status ping_script.service
