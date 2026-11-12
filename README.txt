LOCKDOWN: SITE NYX - server setup (Minecraft Java 26.3, Fabric, PufferPanel on Ubuntu)
==================================================================================

What's in here
  mods/lockdown-site-nyx-0.5.30.jar     the game
  mods/fabric-api-0.165.2+26.3.jar     needed by the game
  mods/voicechat-fabric-2.6.27+26.3.jar  Simple Voice Chat (proximity voice). Needs UDP port 24454 open.
  mods/SkinsRestorer-Mod-Fabric-15.12.6.jar  /skin <name>, /skin url <link> [classic|slim]
  mods/Geyser-Fabric-2.12.1-b1298.jar  lets Bedrock players join (UDP port 19132)
  mods/Floodgate-Fabric-2.2.7-b69.jar  Bedrock players join without a Java account
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

BEDROCK PLAYERS (Geyser + Floodgate)
  Bedrock players join with the server's address and port 19132. They don't need any mod.
  Open UDP 19132 on the machine (Oracle Ubuntu images use iptables):
     sudo iptables -I INPUT -p udp --dport 19132 -j ACCEPT && sudo netfilter-persistent save
  and in the Oracle Cloud console: VCN -> Security List -> Add Ingress Rule: source 0.0.0.0/0, UDP, port 19132.
  Lockdown's blocks are sent to them automatically (config/Geyser-Fabric/packs/lockdown_geyser.mcpack, written on start).
  Their menus open as Bedrock windows. Their names start with a dot (.Name) so they never clash with Java names.

RANKS (OWNER, ADMIN, YOUTUBE, VIP)
  /lockdown rank <player> owner|admin|youtube|vip|none     (operators and OWNERs)
  /lockdown ranks                                          everyone with a rank, and what they donated
  The player must have joined once. OWNER and ADMIN can use /lockdown and host rounds without being operators.
  Every rank gets the VIP perks. They are all cosmetic, as Minecraft's usage guidelines require for anything sold:
  the [VIP] tag and name colour, the Royal Hammer and Royal Gold glow, a lobby trail, escape fireworks, a Beast win
  effect, a join message and +25% credits (never XP). Ranks are saved with the stats in config/lockdown_profiles.json.

STORE (VIP and donations)
  The mod serves the store page itself on TCP port 8085. Players type /store in game for the link.
  VIP is lifetime, from the VIP price up (buyers can pay more); donations are any amount from the minimum.
  Open the port first:
       sudo iptables -I INPUT -p tcp --dport 8085 -j ACCEPT && sudo netfilter-persistent save
     and in the Oracle Cloud console: VCN -> Security List -> Add Ingress Rule: source 0.0.0.0/0, TCP, port 8085.
  Start the server once, edit config/lockdown/store.json, then /lockdown store reload (and /lockdown store to check).

  Manual orders ("provider": "manual", the default) - you get paid your own way, e.g. Wise:
       "enabled": true,
       "publicUrl": "http://<your-server-ip>:8085",
       "payLink": "https://...",            your Wise payment link (shown as a Pay now button), or leave empty
       "payTo": "Wise: @yourwisetag",        shown on the order page
       "payMethodsShown": ["Wise"],
       "contact": "message ... on Discord",
       "vipPrice": 299.99, "vipPriceUsd": "5", "minDonation": 50, "orderDays": 7
     Optional: put a payment QR code image at config/lockdown/store_qr.png and it shows on the order page.
     A buyer gets an order code (NYX-XXXXXX) to put in the payment note. Operators and OWNERs get a message in game
     with [Confirm] [Reject] buttons (also /lockdown store orders). Confirm only once the money is in your account.
     Unconfirmed orders are dropped after orderDays.

  Tebex ("provider": "tebex") - Tebex's webstore takes the payments (allowed for game servers), the mod gives the rank:
     1. Make a store at tebex.io (game: Minecraft Java Edition), add a game server in the Tebex control panel
        and copy its SECRET KEY (never share it).
     2. Packages: VIP (one-time) with the command   lockdown store vip {username}
                  Donation (pay what you want) with  lockdown store thank {username}
        Set each command to run even if the player is offline. Add a description of the perks (cosmetic only).
     3. store.json:  "enabled": true, "provider": "tebex", "tebexSecret": "<secret key>",
                     "tebexStoreUrl": "https://<your-store>.tebex.io"
        then lockdown store reload, and lockdown store shows "connected to Tebex store ...".
     Purchases arrive within a couple of minutes (Tebex decides how often the server may ask). Buyers who never joined
     get it on their first join. /store sends players to the Tebex webstore. Port 8085 isn't used in this mode.

  PayMongo ("provider": "paymongo") - fully automatic, GCash, Maya, QR Ph, cards (when PayMongo sign-ups are open):
       "paymongoSecretKey": "sk_test_..." (fake payments) or "sk_live_...", "paymentMethods": ["gcash", "paymaya", "qrph", "card"]
     Payments reach the game within about 10 seconds; no confirming needed.

  Paid orders are logged in config/lockdown/store_state.json; /lockdown ranks lists ranks and donation totals.
  Cracked players (EasyAuth) are known only by name: whoever joins with that name has its VIP.
