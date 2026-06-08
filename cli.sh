#===HQ-CLI===
#!/bin/bash

# Настройка hostname
hostnamectl set-hostname hq-cli.au-team.irpo

# Настрока часового пояса
timedatectl set-timezone Asia/Krasnoyarsk


# Настраиваем файл /etc/hosts
echo "172.16.1.1 web.au-team.irpo" >> /etc/hosts
echo "172.16.2.1 docker.au-team.irpo" >> /etc/hosts

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


