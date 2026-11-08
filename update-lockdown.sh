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
rm -f "$DIR"/mods/lockdown-site-nyx-*.jar "$DIR"/mods/fabric-api-*.jar
cp "$HERE"/mods/*.jar "$DIR/mods/"
id pufferpanel >/dev/null 2>&1 && chown -R pufferpanel:pufferpanel "$DIR"
echo "Updated. Old mod + stats backed up in $DIR/lockdown_backups/$STAMP"
echo "Restart the server in PufferPanel. Players need the new lockdown jar too."
