#!/bin/sh

op_name=$1
shift

### install packages ###
sudo yum update && sudo yum upgrade -y
sudo yum install -y epel-release # deps
sudo yum install -y vim ruby cronie # tools
sudo yum install -y java-1.8.0-openjdk # java
sudo yum install -y fail2ban # security

### set fail2ban and firewall ###
sudo tee /etc/fail2ban/jail.local > /dev/null << EOS
[DEFAULT]
bantime = 86400
banaction = firewallcmd-ipset

[sshd]
enabled = true

[sshd-ddos]
enabled = true
EOS
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --zone=public --permanent --add-port=25565/tcp
sudo firewall-cmd --reload

### set swap ###
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo tee -a /etc/fstab > /dev/null << EOS
/swapfile   swap    swap    sw  0   0
EOS
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50
sudo tee -a /etc/sysctl.conf > /dev/null << EOS

# swap
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOS

### install minecraft ###
sudo mkdir -p /opt/minecraft/server
cd /opt/minecraft/server
curl -L https://s3.amazonaws.com/Minecraft.Download/versions/1.10.2/minecraft_server.1.10.2.jar \
     -o /opt/minecraft/server/minecraft_server.jar
cp /vagrant/mcrcon /opt/minecraft/server/mcrcon
MCRCON_PASS="$(ruby -rsecurerandom -e 'puts SecureRandom.hex(20)')"
echo "$MCRCON_PASS" > /opt/minecraft/server/.mcrcon-pass
tee /opt/minecraft/server/start-minecraft > /dev/null << EOS
#!/bin/sh
PATH=/usr/bin:\$PATH
java -server -Xms512M -Xmx1024M -jar /opt/minecraft/server/minecraft_server.jar nogui
EOS
chmod +x /opt/minecraft/start-minecraft
tee /opt/minecraft/server/eula.txt > /dev/null << EOS
eula=true
EOS

mkdir -p /opt/minecraft/backup/log
cp /vagrant/mc-backup.rb /opt/minecraft/backup
cp /vagrant/crontab /opt/minecraft

sudo adduser --system --shell /sbin/nologin --no-create-home --home /opt/minecraft minecraft
sudo chown -R minecraft /opt/minecraft
sudo chgrp -R minecraft /opt/minecraft
sudo chmod -R o-r /opt/minecraft
sudo -u minecraft crontab /opt/minecraft/crontab

sudo tee /usr/lib/systemd/system/minecraft.service > /dev/null << EOS
[Unit]
Description=Minecraft server

[Service]
Type=simple
User=minecraft
Group=minecraft
WorkingDirectory=/opt/minecraft/server
ExecStart=/opt/minecraft/server/start-minecraft
# Timeout for start up/shut down
TimeoutSec=300

[Install]
WantedBy=graphical.target
EOS
sudo systemctl start minecraft
sudo systemctl enable minecraft
sleep 10
sudo systemctl stop minecraft
sudo -u minecraft sed -i '/white-list=.*/d' /opt/minecraft/server/server.properties
sudo -u minecraft sed -i '/enable-rcon=.*/d' /opt/minecraft/server/server.properties
sudo -u minecraft tee -a /opt/minecraft/server/server.properties > /dev/null <<EOS
white-list=true
enable-rcon=true
rcon.password=$MCRCON_PASS
EOS
sudo systemctl start minecraft
sudo -u minecraft /opt/minecraft/server/mcrcon -p $MCRCON_PASS "op $op_name"
