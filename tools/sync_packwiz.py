#!/usr/bin/env python3
"""Rebuild the packwiz pack (packwiz/) from what is actually in mods/ and config/.

- every jar in mods/ gets a packwiz/mods/<name>.pw.toml (Modrinth jars are looked up by hash, Lockdown points at this repo)
- config/ is mirrored to packwiz/config/
- pack.toml version = the Lockdown version, index.toml hashes are recomputed
Run from anywhere:  python3 tools/sync_packwiz.py      (exit code 0; prints what changed)
"""
import hashlib, json, os, re, shutil, sys, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PW = os.path.join(ROOT, 'packwiz')
RAW = 'https://raw.githubusercontent.com/ZebyWebby/lockdown-site-nyx/main/'
SERVER_ONLY = ('easyauth', 'skinsrestorer', 'geyser', 'floodgate')   # project slugs / name prefixes that clients don't need


def sha(path, algo):
    h = hashlib.new(algo)
    with open(path, 'rb') as f:
        for b in iter(lambda: f.read(1 << 20), b''):
            h.update(b)
    return h.hexdigest()


def q(s):
    return json.dumps(s)   # TOML basic strings are compatible with JSON strings for our content


def modrinth(sha512):
    req = urllib.request.Request(f'https://api.modrinth.com/v2/version_file/{sha512}?algorithm=sha512',
                                 headers={'User-Agent': 'lockdown-site-nyx-packwiz-sync'})
    with urllib.request.urlopen(req, timeout=30) as r:
        v = json.load(r)
    with urllib.request.urlopen(urllib.request.Request(f'https://api.modrinth.com/v2/project/{v["project_id"]}',
                                                       headers={'User-Agent': 'lockdown-site-nyx-packwiz-sync'}), timeout=30) as r:
        p = json.load(r)
    f = next(x for x in v['files'] if x['hashes']['sha512'] == sha512)
    return p, v, f


def main():
    mods_dir = os.path.join(ROOT, 'mods')
    jars = sorted(x for x in os.listdir(mods_dir) if x.endswith('.jar'))
    lockdown = [x for x in jars if x.startswith('lockdown-site-nyx-')]
    if len(lockdown) != 1:
        sys.exit(f'expected exactly one lockdown jar in mods/, found {lockdown}')
    version = lockdown[0][len('lockdown-site-nyx-'):-4]

    # --- mods
    out_mods = os.path.join(PW, 'mods')
    os.makedirs(out_mods, exist_ok=True)
    wanted = {}
    for jar in jars:
        path = os.path.join(mods_dir, jar)
        if jar in lockdown:
            wanted['lockdown-site-nyx.pw.toml'] = (
                f'name = "Lockdown: Site Nyx"\nfilename = {q(jar)}\nside = "both"\n\n[download]\n'
                f'url = {q(RAW + "mods/" + jar)}\nhash-format = "sha256"\nhash = {q(sha(path, "sha256"))}\n')
            continue
        p, v, f = modrinth(sha(path, 'sha512'))
        slug = p['slug']
        side = 'server' if any(slug.lower().startswith(s) or jar.lower().startswith(s) for s in SERVER_ONLY) else 'both'
        wanted[f'{slug}.pw.toml'] = (
            f'name = {q(p["title"])}\nfilename = {q(f["filename"])}\nside = {q(side)}\n\n[download]\n'
            f'url = {q(f["url"])}\nhash-format = "sha512"\nhash = {q(f["hashes"]["sha512"])}\n\n'
            f'[update]\n[update.modrinth]\nmod-id = {q(p["id"])}\nversion = {q(v["id"])}\n')
    for old in os.listdir(out_mods):
        if old.endswith('.pw.toml') and old not in wanted:
            os.remove(os.path.join(out_mods, old))
    for name, text in wanted.items():
        with open(os.path.join(out_mods, name), 'w') as fh:
            fh.write(text)

    # --- config mirror
    out_cfg = os.path.join(PW, 'config')
    shutil.rmtree(out_cfg, ignore_errors=True)
    if os.path.isdir(os.path.join(ROOT, 'config')):
        shutil.copytree(os.path.join(ROOT, 'config'), out_cfg)

    # --- index.toml
    ignore = {'pack.toml', 'index.toml', 'README.md', '.packwizignore'}
    entries = []
    for base, _, files in os.walk(PW):
        for fn in files:
            rel = os.path.relpath(os.path.join(base, fn), PW).replace(os.sep, '/')
            if rel in ignore:
                continue
            entries.append(rel)
    idx = ['hash-format = "sha256"', '']
    for rel in sorted(entries):
        idx += ['[[files]]', f'file = {q(rel)}', f'hash = {q(sha(os.path.join(PW, rel), "sha256"))}']
        if rel.endswith('.pw.toml'):
            idx.append('metafile = true')
        idx.append('')
    with open(os.path.join(PW, 'index.toml'), 'w') as fh:
        fh.write('\n'.join(idx).rstrip('\n') + '\n')

    # --- pack.toml
    pack = os.path.join(PW, 'pack.toml')
    text = open(pack).read()
    text = re.sub(r'(?m)^version = ".*"$', f'version = {q(version)}', text, count=1)
    text = re.sub(r'(?m)^hash = ".*"$', f'hash = {q(sha(os.path.join(PW, "index.toml"), "sha256"))}', text, count=1)
    with open(pack, 'w') as fh:
        fh.write(text)

    # --- README table
    readme = os.path.join(PW, 'README.md')
    if os.path.exists(readme):
        r = open(readme).read()
        r = re.sub(r'Lockdown: Site Nyx \d+\.\d+\.\d+ \|', f'Lockdown: Site Nyx {version} |', r)
        with open(readme, 'w') as fh:
            fh.write(r)
    print(f'packwiz pack synced: lockdown {version}, {len(wanted)} mods, {len(entries)} files')


if __name__ == '__main__':
    main()
