#===HQ-CLI===
#!/bin/bash

# Настройка hostname
hostnamectl set-hostname hq-cli.au-team.irpo

# Настрока часового пояса
timedatectl set-timezone Asia/Krasnoyarsk

# Создаем директорию для сетевого интерфейса
mkdir /etc/net/ifaces/enp0s3

# Настройка ethernet-интерфейса
cat <<EOF > /etc/net/ifaces/enp0s3/options
BOOTPROTO=dhcp
TYPE=eth
CONFIG_WIRELANDS=no
SYSTEMD_BOOTPROTO=dhcp4
CONFIG_IPV4=yes
DISABLED=no
NM_CONTROLLED=no
SYSTEMD_CONTROLLED=no
EOF


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
Subsystem sftp internal-sftp
EOF

# Запуск и включение SSH
systemctl enable --now sshd
systemctl restart sshd

exec bash


