#===HQ-SRV===
#!/bin/bash

# Настройка hostname
hostnamectl set-hostname hq-srv.au-team.irpo

# Настрока часового пояса
timedatectl set-timezone Asia/Krasnoyarsk

# Настраиваем интерфейс enp0s3 (статический IP)
cat <<EOF > /etc/net/ifaces/enp0s3/options
BOOTPROTO=static
TYPE=eth
CONFIG_WIRELESS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
EOF

cat <<EOF > /etc/net/ifaces/enp0s3/ipv4address
192.168.1.2/27
EOF

cat <<EOF > /etc/net/ifaces/enp0s3/ipv4route
default via 192.168.1.1
EOF

# Добавление адреса DNS-сервера
cat <<EOF > /etc/resolv.conf
search au-team.irpo
nameserver 192.168.1.2
nameserver 77.88.8.8
EOF

# Перезапуск сетевой службы
systemctl restart network

# Создаем нового пользователя sshuser
useradd sshuser -u 2026 -p $(openssl passwd -1 "P@ssw0rd")
usermod -aG wheel sshuser
chage -M -1 -I -1 -E -1 sshuser

# Sudo без ввода пароля
sed -i "s/# WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL/" "/etc/sudoers"

# Изменение настроек SSH
cat <<EOF > /etc/openssh/sshd_config
Port 2026
MaxAuthTries 2
AllowUsers sshuser
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




