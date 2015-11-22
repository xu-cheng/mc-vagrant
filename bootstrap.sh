#!/bin/sh

op_name=$1
shift

sudo yum update && sudo yum upgrade -y
sudo yum install -y epel-release # deps
sudo yum install -y vim tmux # tools
sudo yum install -y java-1.8.0-openjdk # java
sudo yum install -y fail2ban # security

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

sudo mkdir /opt/minecraft
cd /opt/minecraft
curl -L https://s3.amazonaws.com/Minecraft.Download/versions/1.8.8/minecraft_server.1.8.8.jar \
     -o /opt/minecraft/minecraft_server.jar
tee /opt/minecraft/start-minecraft > /dev/null << EOS
#!/bin/sh
PATH=/usr/bin:\$PATH
java -server -Xms512M -Xmx1024M -jar /opt/minecraft/minecraft_server.jar nogui
EOS
tee /opt/minecraft/eula.txt > /dev/null << EOS
eula=true
EOS
chmod +x /opt/minecraft/start-minecraft
tmux new-session -d -s minecraft-tmp /opt/minecraft/start-minecraft
sleep 15
tmux send -t minecraft-tmp:0 /op SPACE "$op_name" ENTER
sleep 15
tmux kill-server
sed -i 's/white-list=.*/white-list=true/g' /opt/minecraft/server.properties
sudo adduser --system --shell /sbin/nologin --no-create-home --home /opt/minecraft minecraft
sudo chown -R minecraft /opt/minecraft
sudo chgrp -R minecraft /opt/minecraft

sudo tee /usr/lib/systemd/system/minecraft.service > /dev/null << EOS
[Unit]
Description=Minecraft server

[Service]
Type=simple
User=minecraft
Group=minecraft
WorkingDirectory=/opt/minecraft
ExecStart=/opt/minecraft/start-minecraft
# Timeout for start up/shut down
TimeoutSec=300

[Install]
WantedBy=graphical.target
EOS
sudo systemctl start minecraft
sudo systemctl enable minecraft
