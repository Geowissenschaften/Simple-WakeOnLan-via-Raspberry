#!/bin/bash
set -o nounset  # treat unset variables as an error when substituting
set -o pipefail # the return value of a pipeline is the status of
                #    the last command to exit with a non-zero status,
                #    or zero if no command exited with a non-zero status
set -o errexit  # exit immediately if a command exits with a non-zero status

function print_error {
    read line file <<<$(caller)
    echo "An error occurred in line $line of file $file:" >&2
    sed "${line}q;d" "$file" >&2
}
trap print_error ERR
# https://codeinthehole.com/tips/bash-error-reporting/
# https://google.github.io/styleguide/shell.xml
##############################################################################
##############################################################################

WOLServerPort="55555"

apt-get --assume-yes install etherwake

adduser --quiet --disabled-login --gecos "" etherwake

cat > /etc/sudoers.d/etherwake <<-EOF
etherwake ALL=(ALL) NOPASSWD: /usr/sbin/etherwake [[\:xdigit\:]][[\:xdigit\:]]\:[[\:xdigit\:]][[\:xdigit\:]]\:[[\:xdigit\:]][[\:xdigit\:]]\:[[\:xdigit\:]][[\:xdigit\:]]\:[[\:xdigit\:]][[\:xdigit\:]]\:[[\:xdigit\:]][[\:xdigit\:]]
EOF

cat > /etc/systemd/system/SendMagicPacket.socket <<EOF 
[Unit]
Description=WakeOnLAN - SendMagicPacket - socket

[Socket]
# Ports: 49152-65535 
# These are used by client programs and you are free to use these in client programs. 
# Also known as ephemeral ports.
ListenStream=${WOLServerPort}
Accept=yes

[Install]
WantedBy=sockets.target
EOF

cat > /etc/systemd/system/SendMagicPacket@.service <<EOF
[Unit]
Description=WakeOnLAN - SendMagicPacket - service
After=network.target SendMagicPacket.socket
Requires=SendMagicPacket.socket

[Service]
Type=oneshot
ExecStart=/bin/bash $(echo ~etherwake/bin/SendMagicPacket.sh)
User=etherwake
Group=etherwake
StandardInput=socket
TimeoutStopSec=5

[Install]
WantedBy=multi-user.target
EOF

su etherwake --command "mkdir --parents ~/bin/"
cat > ~etherwake/bin/SendMagicPacket.sh <<'EOF'
#!/bin/bash

read MacAddress
# echo $MacAddress
if [[ "$MacAddress" =~ ^(([a-fA-F0-9]{2}:){5}[a-fA-F0-9]{2})[[:space:]]*$ ]]; then
    sudo /usr/sbin/etherwake ${BASH_REMATCH[1]}
    echo `date` - waking MAC address: ${BASH_REMATCH[1]}
else
    echo `date` - failure \"$MacAddress\" is not a valid MAC address
fi
EOF
chown --no-dereference etherwake:etherwake ~etherwake/bin/SendMagicPacket.sh

systemctl start SendMagicPacket.socket
systemctl enable SendMagicPacket.socket
