#!/bin/bash
# Lockdown: Site Nyx - install into a PufferPanel Minecraft server folder.
# Usage:  sudo ./install-lockdown.sh /var/lib/pufferpanel/servers/<server-id>
set -e
DIR="${1:?usage: sudo ./install-lockdown.sh /var/lib/pufferpanel/servers/<server-id>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -d "$DIR" ] || { echo "Folder $DIR does not exist"; exit 1; }

# 1) Java 25 (Minecraft 26.3 needs it). Installed to /opt/java25 if the system java is older.
if /opt/java25/bin/java -version 2>&1 | grep -q 'version "25'; then
  echo "Java 25 already in /opt/java25"
else
  case "$(uname -m)" in x86_64) A=x64 ;; aarch64|arm64) A=aarch64 ;; *) echo "Unknown CPU $(uname -m)"; exit 1 ;; esac
  echo "Installing Java 25 (Eclipse Temurin, $A) to /opt/java25 ..."
  mkdir -p /opt/java25
  curl -fsSL "https://api.adoptium.net/v3/binary/latest/25/ga/linux/$A/jdk/hotspot/normal/eclipse" | tar xz -C /opt/java25 --strip-components=1
fi
/opt/java25/bin/java -version

# 2) Fabric server launcher + mods
mkdir -p "$DIR/mods"
cp "$HERE/fabric-server-launch.jar" "$DIR/"
rm -f "$DIR"/mods/lockdown-site-nyx-*.jar "$DIR"/mods/fabric-api-*.jar
cp "$HERE"/mods/*.jar "$DIR/mods/"

# 3) server.properties: the Lockdown world type (only used when a NEW world is created)
touch "$DIR/server.properties"
ALREADY_LOCKDOWN=0
grep -q "^level-type=lockdown" "$DIR/server.properties" && ALREADY_LOCKDOWN=1
setprop() {
  local esc
  esc=$(printf '%s' "$2" | sed 's/[\\&|]/\\&/g')
  if grep -q "^$1=" "$DIR/server.properties"; then sed -i "s|^$1=.*|$1=$esc|" "$DIR/server.properties"; else printf '%s=%s\n' "$1" "$2" >> "$DIR/server.properties"; fi
}
setprop level-name world
setprop level-type 'lockdown\:site_nyx'
setprop spawn-protection 0
setprop allow-flight true
setprop max-players 10

# 4) A non-Lockdown world is kept as a backup (never deleted), so the Lockdown world gets generated fresh.
#    An existing Lockdown world is kept as it is (updates rebuild the lobby and maps by themselves).
if [ -d "$DIR/world" ] && [ "$ALREADY_LOCKDOWN" = 0 ]; then
  B="$DIR/world_backup_$(date +%Y%m%d_%H%M%S)"
  mv "$DIR/world" "$B"
  echo "Old world moved to $B"
fi

# 5) Minecraft EULA (https://aka.ms/MinecraftEULA) - you have to accept it yourself
if ! grep -q "eula=true" "$DIR/eula.txt" 2>/dev/null; then
  read -r -p "Do you accept the Minecraft EULA (https://aka.ms/MinecraftEULA)? [y/N] " ok
  if [ "$ok" = "y" ] || [ "$ok" = "Y" ]; then echo "eula=true" > "$DIR/eula.txt"; else echo "Not accepted - the server will not start until eula.txt says eula=true"; fi
fi

# 6) PufferPanel runs servers as the pufferpanel user
id pufferpanel >/dev/null 2>&1 && chown -R pufferpanel:pufferpanel "$DIR"
echo
echo "Done. In PufferPanel set the server's start command to:"
echo "  /opt/java25/bin/java -Xms2G -Xmx4G -jar fabric-server-launch.jar nogui"
echo "then start the server. The first start builds the lobby and all 10 maps (takes a moment)."
