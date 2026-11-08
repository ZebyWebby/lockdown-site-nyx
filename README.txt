LOCKDOWN: SITE NYX - server setup (Minecraft Java 26.3, Fabric, PufferPanel on Ubuntu)
==================================================================================

What's in here
  mods/lockdown-site-nyx-0.5.10.jar     the game
  mods/fabric-api-0.165.2+26.3.jar     needed by the game
  mods/voicechat-fabric-2.6.27+26.3.jar  Simple Voice Chat (proximity voice). Needs UDP port 24454 open.
  mods/SkinsRestorer-Mod-Fabric-15.12.6.jar  /skin <name>, /skin url <link> [classic|slim]
  mods/easyauth-mc26.3-3.4.4.jar       lets cracked players join; premium players keep their accounts and stats
  config/EasyAuth/                     EasyAuth settings (no passwords; premium names stay protected)
  fabric-server-launch.jar             Fabric server (Minecraft 26.3, loader 0.20.1) - downloads the game files on first start
  install-lockdown.sh                  first-time setup of a PufferPanel server
  update-lockdown.sh                   updates an existing Lockdown server (keeps world, levels and stats)

1. In PufferPanel, create a new server (any Minecraft Java template, e.g. "Vanilla" or "Fabric").
   Note its ID (it's in the page address: /server/<ID>). Don't start it yet.

2. Copy this folder to the Ubuntu machine, e.g. from your PC:
     scp -r lockdown-server ubuntu@<your-server-ip>:~/
   then on the server:
     cd ~/lockdown-server
     sudo bash ./install-lockdown.sh /var/lib/pufferpanel/servers/<ID>
   (The folder may be different on your install - it's the one that has server.properties after a first start.)

3. In PufferPanel (Admin / server settings) change the start command to:
     /opt/java25/bin/java -Xms2G -Xmx4G -jar fabric-server-launch.jar nogui
   (Use less memory than -Xmx4G if the machine is small.)

4. Start the server. The first start downloads Minecraft 26.3 and builds the lobby + 10 maps.
   Players need Minecraft 26.3 with Fabric Loader 0.20.1, Fabric API and the same lockdown jar in their mods folder.

5. Open TCP port 25565 to players (Ubuntu: sudo ufw allow 25565/tcp; on Oracle Cloud also add an Ingress rule
   for 25565 in the VCN security list).

Admin commands (operators): /lockdown build  /lockdown lobby  /lockdown map <0-9>
Player menu: the book in the lobby (or /nyx menu).

UPDATING (keeps levels, stats and cosmetics)
  Stop the server in PufferPanel, copy the new lockdown-server folder over, then:
     cd ~/lockdown-server
     sudo bash ./update-lockdown.sh /var/lib/pufferpanel/servers/<ID>
  Start the server again. Stats live in config/lockdown_profiles.json and a backup is made in lockdown_backups/ each time.

VOICE CHAT (Simple Voice Chat)
  Open UDP port 24454 on the machine (Oracle Ubuntu images use iptables):
     sudo iptables -I INPUT -p udp --dport 24454 -j ACCEPT && sudo netfilter-persistent save
  and in the Oracle Cloud console: VCN -> Security List -> Add Ingress Rule: source 0.0.0.0/0, UDP, port 24454.
  Players' Lockdown mod installs Simple Voice Chat by itself (restart Minecraft once). Press V in game for settings.

CRACKED PLAYERS (EasyAuth)
  server.properties keeps online-mode=true - EasyAuth lets cracked players in by itself, with no /register or /login.
  Premium players are recognised automatically and keep their UUID, so levels/stats are untouched.
  A cracked player whose name belongs to a paid account can't join with it (that protects real accounts).
  If that happens to a friend, run in the console:  auth markAsOffline <name>
  Don't make cracked players operators: EasyAuth would ask them for a password.

SKINS (SkinsRestorer)
  /skin <player name>          copy any premium player's skin
  /skin url <image link> [classic|slim]   use a skin image from the web (direct .png link)
