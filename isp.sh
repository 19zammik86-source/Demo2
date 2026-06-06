#===ISP===
#!/bin/bash

# Настройка hostname
hostnamectl set-hostname isp.au-team.irpo

# Настрока часового пояса
timedatectl set-timezone Asia/Krasnoyarsk

# Создаем директории для интерфейсов
mkdir -p /etc/net/ifaces/{enp0s8,enp0s9}

# Настраиваем интерфейс enp0s8 (статический IP)
cat <<EOF > /etc/net/ifaces/enp0s8/options
BOOTPROTO=static
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
EOF

# Настраиваем интерфейс enp0s9 (статический IP)
cat <<EOF > /etc/net/ifaces/enp0s9/options
BOOTPROTO=static
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
EOF

# Устанавливаем статические адреса для интерфейсов
echo '172.16.1.1/28' > /etc/net/ifaces/enp0s8/ipv4address
echo '172.16.2.1/28' > /etc/net/ifaces/enp0s9/ipv4address

# Настройка маршутизации
sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/" "/etc/net/sysctl.conf"

# Настройка NAT
iptables -t nat -A POSTROUTING -o enp0s3 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables

# Добавляем IPTABLES в автозапуск
systemctl enable --now iptables

# Перезапускаем сеть
systemctl restart network

# Разрешаем root доступ по SSH
sed -i 's/#*PermitRootLogin.*/PermitRootLogin yes/' /etc/openssh/sshd_config

# Перезапускаем сервис SSHD
systemctl enable --now sshd
systemctl restart sshd.service

apt-get update

exec bash
