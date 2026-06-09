#===HQ-RTR===
#!/bin/bash

# Настройка hostname
hostnamectl set-hostname hq-rtr.au-team.irpo

# Настрока часового пояса
timedatectl set-timezone Asia/Krasnoyarsk

# Создаем директории для интерфейсов
mkdir -p /etc/net/ifaces/enp0s8
mkdir -p /etc/net/ifaces/enp0s8.100
mkdir -p /etc/net/ifaces/enp0s8.200
mkdir -p /etc/net/ifaces/enp0s8.999
mkdir -p /etc/net/ifaces/gre1


# Настраиваем интерфейс enp0s8 (статический IP)
cat <<EOF > /etc/net/ifaces/ens19/options
BOOTPROTO=static
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
EOF

# Настраиваем VLAN enp0s8.100
cat <<EOF > /etc/net/ifaces/enp0s8.100/options
BOOTPROTO=static
TYPE=vlan
HOST=enp0s8
VID=100
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
EOF

cat <<EOF > /etc/net/ifaces/enp0s8.100/ipv4address
192.168.1.1/27
EOF

# Настраиваем VLAN enp0s8.200
cat <<EOF > /etc/net/ifaces/enp0s8.200/options
BOOTPROTO=static
TYPE=vlan
HOST=enp0s8
VID=200
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
EOF

cat <<EOF > /etc/net/ifaces/enp0s8.200/ipv4address
192.168.2.1/28
EOF

# Настраиваем VLAN enp0s8.999
cat <<EOF > /etc/net/ifaces/enp0s8.999/options
BOOTPROTO=static
TYPE=vlan
HOST=enp0s8
VID=999
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
EOF

cat <<EOF > /etc/net/ifaces/enp0s8.999/ipv4address
192.168.99.1/29
EOF

# Настраиваем gre1
cat <<EOF > /etc/net/ifaces/gre1/options
TYPE=iptun
TUNTYPE=gre
TUNLOCAL=172.16.1.2
TUNREMOTE=172.16.2.2
TUNOPTIONS='ttl 64'
EOF

cat <<EOF > /etc/net/ifaces/gre1/ipv4address
10.0.0.1/30
EOF

cat <<EOF > /etc/net/ifaces/gre1/ipv4route
192.168.3.0/28 via 10.0.0.2
EOF

modprobe 8021q

# Настройка маршутизации
sed -i "s/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/" "/etc/net/sysctl.conf"

# Настройка iptables
iptables -t nat -A POSTROUTING -o ens18 -j MASQUERADE
iptables -t nat -A PREROUTING -i ens18 -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.2:80
iptables -t nat -A PREROUTING -i ens18 -p tcp --dport 2026 -j DNAT --to-destination 192.168.1.2:2026
iptables-save > /etc/sysconfig/iptables

# Добавляем IPTABLES в автозапуск
systemctl enable --now iptables

# Добавление адреса DNS-сервера
cat <<EOF > /etc/resolv.conf
search au-team.irpo
nameserver 192.168.1.2
nameserver 77.88.8.8
EOF

# Перезапуск сетевой службы
systemctl restart network

# Создаем пользователя net_admin
useradd net_admin -m -p $(openssl passwd -1 "P@ssw0rd")
usermod -aG wheel net_admin
chage -M -1 -I -1 -E -1 net_admin

# Sudo без ввода пароля
sed -i "s/# WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/" "/etc/sudoers"

# Изменение настроек SSH
cat <<EOF > /etc/openssh/sshd_config
Port 2026
MaxAuthTries 2
AllowUsers net_admin
PermitRootLogin no
Banner /root/banner
Subsystem sftp internal-sftp
EOF

# Создание баннера для SSH
cat <<EOF > /root/banner
Authorized access only

EOF

# Запуск и включение SSH
systemctl enable --now sshd
systemctl restart sshd

apt-get update

exec bash

