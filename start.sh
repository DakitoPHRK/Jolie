#!/bin/bash

echo "Aplicando cambios..."
sleep 2
# Dak1
echo -e "nameserver 131.221.32.2\nnameserver 131.221.32.3\nnameserver 2803:3b80::2\nnameserver 2803:3b80::3" > dns

cp dns /tmp/resolv.conf.d/resolv.conf.auto
# Dak2
chmod +x /etc/rc.local

# Dak3
echo -e "#!/bin/bash\n\ncp /root/dns /tmp/resolv.conf.d/resolv.conf.auto\nexit 0" > /etc/rc.local

echo "Todo Listo!"
