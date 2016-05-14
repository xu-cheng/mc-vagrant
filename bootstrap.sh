#!/bin/sh

op_name=$1
shift

### install packages ###
sudo yum update && sudo yum upgrade -y
sudo yum install -y epel-release # deps
sudo yum install -y vim tmux # tools
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
curl -L https://s3.amazonaws.com/Minecraft.Download/versions/1.8.8/minecraft_server.1.8.8.jar \
     -o /opt/minecraft/server/minecraft_server.jar
tee /opt/minecraft/server/start-minecraft > /dev/null << EOS
#!/bin/sh
PATH=/usr/bin:\$PATH
java -server -Xms512M -Xmx1024M -jar /opt/minecraft/server/minecraft_server.jar nogui
EOS
tee /opt/minecraft/server/eula.txt > /dev/null << EOS
eula=true
EOS
chmod +x /opt/minecraft/start-minecraft
tmux new-session -d -s minecraft-tmp /opt/minecraft/server/start-minecraft
sleep 15
tmux send -t minecraft-tmp:0 /op SPACE "$op_name" ENTER
sleep 15
tmux kill-server
sed -i 's/white-list=.*/white-list=true/g' /opt/minecraft/server/server.properties

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
