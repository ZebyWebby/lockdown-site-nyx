# Lockdown: Site Nyx, packwiz pack

The same mod set as the server bundle in the repo root, as a [packwiz](https://packwiz.infra.link) pack.
Every jar is pinned to the exact version (and hash) that ships in `mods/`.

| mod | side | source |
| --- | --- | --- |
| Lockdown: Site Nyx 0.5.8 | both | this repo (`mods/`) |
| Fabric API 0.165.2+26.3 | both | Modrinth |
| Simple Voice Chat 2.6.27+26.3 | both | Modrinth |
| EasyAuth 3.4.4 | server | Modrinth |
| SkinsRestorer 15.12.6 | server | Modrinth |

`config/EasyAuth/` is included too (packwiz can't mark plain files as server only, so clients get it as well; it does nothing there).

Minecraft 26.3, Fabric Loader 0.20.1, Java 25.

## Players

In Prism Launcher (or MultiMC), make a Minecraft 26.3 + Fabric 0.20.1 instance, put
[packwiz-installer-bootstrap.jar](https://github.com/packwiz/packwiz-installer-bootstrap/releases) in the instance's
`.minecraft` folder and set the pre-launch command (Edit Instance, Settings, Custom commands) to:

    "$INST_JAVA" -jar packwiz-installer-bootstrap.jar https://raw.githubusercontent.com/ZebyWebby/lockdown-site-nyx/main/packwiz/pack.toml

The mods are installed and kept up to date every time the game starts.

## Server

From the server folder (next to `fabric-server-launch.jar`):

    java -jar packwiz-installer-bootstrap.jar -g -s server https://raw.githubusercontent.com/ZebyWebby/lockdown-site-nyx/main/packwiz/pack.toml

`-s server` installs the server-only mods (EasyAuth, SkinsRestorer) as well. This only handles mods and configs;
`install-lockdown.sh` is still the way to set up Java 25, `server.properties` and the EULA on a fresh server.

## Updating the pack

After a new release is committed to `mods/`:

    cd packwiz
    packwiz remove lockdown-site-nyx
    packwiz url add "Lockdown: Site Nyx" https://raw.githubusercontent.com/ZebyWebby/lockdown-site-nyx/main/mods/lockdown-site-nyx-<version>.jar --meta-name lockdown-site-nyx
    # then bump `version` in pack.toml and, for the other mods:
    packwiz update --all
    packwiz refresh

Push the new jar before (or together with) the pack change, since the pack points at its raw GitHub URL.
