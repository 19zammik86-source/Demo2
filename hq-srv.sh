#===HQ-SRV===
#!/bin/bash

# Настройка hostname
hostnamectl set-hostname hq-srv.au-team.irpo

# Настрока часового пояса
timedatectl set-timezone Asia/Krasnoyarsk

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




