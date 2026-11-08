#!/bin/bash
# Lockdown: Site Nyx - update an existing server to the mod version in this folder.
# Keeps the world, levels, stats and cosmetics. The lobby is refreshed on the next start, maps whenever they are played.
# Usage:  sudo bash ./update-lockdown.sh /var/lib/pufferpanel/servers/<server-id>
set -e
DIR="${1:?usage: sudo bash ./update-lockdown.sh /var/lib/pufferpanel/servers/<server-id>}"
HERE="$(cd "$(dirname "$0")" && pwd)"
[ -d "$DIR/mods" ] || { echo "No mods folder in $DIR - is this the Lockdown server?"; exit 1; }
STAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p "$DIR/lockdown_backups/$STAMP"
cp "$DIR"/mods/lockdown-site-nyx-*.jar "$DIR/lockdown_backups/$STAMP/" 2>/dev/null || true
for f in "$DIR/config/lockdown_profiles.json" "$DIR/world/lockdown_profiles.json"; do [ -f "$f" ] && cp "$f" "$DIR/lockdown_backups/$STAMP/"; done
rm -f "$DIR"/mods/lockdown-site-nyx-*.jar "$DIR"/mods/fabric-api-*.jar "$DIR"/mods/voicechat-*.jar "$DIR"/mods/SkinsRestorer-*.jar "$DIR"/mods/easyauth-*.jar
cp "$HERE"/mods/*.jar "$DIR/mods/"
# EasyAuth: premium players are recognised automatically (and keep their stats); cracked players join without a password
mkdir -p "$DIR/config/EasyAuth"
cp "$HERE"/config/EasyAuth/main.conf "$HERE"/config/EasyAuth/extended.conf "$DIR/config/EasyAuth/"
for f in storage.conf technical.conf translation.conf; do   # EasyAuth needs all of them; keep any existing ones
  [ -f "$DIR/config/EasyAuth/$f" ] || cp "$HERE/config/EasyAuth/$f" "$DIR/config/EasyAuth/"
done
setprop() {
  local esc
  esc=$(printf '%s' "$2" | sed 's/[\\&|]/\\&/g')
  if grep -q "^$1=" "$DIR/server.properties"; then sed -i "s|^$1=.*|$1=$esc|" "$DIR/server.properties"; else printf '%s=%s\n' "$1" "$2" >> "$DIR/server.properties"; fi
}
if [ -f "$DIR/server.properties" ]; then
  setprop online-mode true             # EasyAuth needs this; it lets cracked players in by itself
  setprop enforce-secure-profile false # cracked players can't sign chat messages
fi
id pufferpanel >/dev/null 2>&1 && chown -R pufferpanel:pufferpanel "$DIR"
echo "Updated. Old mod + stats backed up in $DIR/lockdown_backups/$STAMP"
echo "Restart the server in PufferPanel. Players need the new lockdown jar too."
