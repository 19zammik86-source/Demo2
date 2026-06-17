apt-get update

apt-get install -y task-samba-dc

for service in smb nmb krb5kdc slapd bind;
do
  systemctl disable $service --now;
done

rm -f /etc/samba/smb.conf

rm -f /etc/cache/smb.conf

rm -rf /var/lib/samba 
rm -rf /var/cache/samba

mkdir -p /var/lib/samba/sysvol

samba-tool domain provision \
  --realm="AU-TEAM.IRPO" \
  --domain="AU-TEAM" \
  --server-role="dc" \
  --dns-backend="SAMBA_INTERNAL" \
  --option="dns forwarder=192.168.100.2" \
  --adminpass="P@ssw0rd" 

systemctl enable --now samba

/bin/cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

systemctl restart samba

cat > "/etc/net/ifaces/enp7s1/resolv.conf" <<EOF
search au-team.irpo
nameserver 127.0.0.1
EOF

systemctl restart network

echo "P@ssw0rd" | kinit Administrator@AU-TEAM.IRPO

samba-tool group add hq

for i in {1..5};
do
  samba-tool user add hquser$i P@ssw0rd;
  samba-tool user setexpiry hquser$i --noexpiry;
  samba-tool group addmembers "hq" hquser$i;
done

cat > /etc/chrony.conf <<EOF
server 172.16.2.1 iburst
EOF

systemctl restart chronyd

apt-get update

apt-get install -y ansible sshpass python3-module-pip

cat > /etc/ansible/hosts <<EOF
HQ-SRV ansible_host=192.168.100.2 ansible_user=sshuser ansible_password=P@ssw0rd ansible_port=2026
HQ-CLI ansible_host=192.168.200.2 ansible_user=user ansible_password=resu
HQ-RTR ansible_host=10.10.10.1 ansible_user=net_admin ansible_password=P@ssw0rd ansible_connection=network_cli ansible_network_os=ios
BR-RTR ansible_host=192.168.0.1 ansible_user=net_admin ansible_password=P@ssw0rd ansible_connection=network_cli ansible_network_os=ios

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF

cat > /etc/ansible/ansible.cfg <<EOF
[defaults]
inventory = /etc/ansible/hosts
host_key_checking = False
EOF

ansible-galaxy collection install ansible.netcommon

ansible-galaxy collection install cisco.ios

pip3 install ansible-pylibssh

sleep 1m

ansible -m ping all

apt-get update

apt-get install -y docker-engine docker-compose-v2

systemctl enable --now docker.service

mount /dev/sr0 /mnt/

docker load < /mnt/docker/site_latest.tar

docker load < /mnt/docker/mariadb_latest.tar

cat > compose.yaml <<EOF
services:
  database:
    container_name: db
    image: mariadb:10.11
    restart: always
    ports:
      - "3306:3306"
    environment:
      MARIADB_DATABASE: "testdb"
      MARIADB_USER: "testc"
      MARIADB_PASSWORD: "P@ssw0rd"
      MARIADB_ROOT_PASSWORD: "toor"

  app:
    container_name: testapp
    image: site:latest
    restart: always
    ports:
      - "8080:8000"
    environment:
      DB_TYPE: "maria"
      DB_HOST: "database"
      DB_PORT: "3306"
      DB_NAME: "testdb"
      DB_USER: "testc"
      DB_PASS: "P@ssw0rd"
    depends_on:
      - database
EOF

docker compose up -d

docker compose ps
