#!/usr/bin/env python3
import os
import json
import subprocess
import argparse
import fcntl
from pathlib import Path

CONFIG_FILE = Path.home() / ".vdrive.json"

def load_config():
    if not CONFIG_FILE.exists():
        return {}
    with open(CONFIG_FILE, "r") as f:
        try:
            fcntl.flock(f, fcntl.LOCK_SH)
            return json.load(f)
        finally:
            fcntl.flock(f, fcntl.LOCK_UN)

def save_config(config):
    with open(CONFIG_FILE, "w") as f:
        try:
            fcntl.flock(f, fcntl.LOCK_EX)
            json.dump(config, f, indent=2)
        finally:
            fcntl.flock(f, fcntl.LOCK_UN)

def create(name, size_mb):
    if os.geteuid() != 0:
        print("[!] This command requires root privileges.")
        return
    path = Path.home() / f"{name}.img"
    if path.exists():
        print(f"[!] Virtual drive {name} already exists")
        return

    print(f"[+] Creating virtual drive {path} ({size_mb} MB)...")
    try:
        with open(path, "wb") as f:
            f.truncate(size_mb * 1024 * 1024)

        # Automatically format as ext4
        subprocess.run(["mkfs.ext4", "-F", str(path)], check=True)
        print(f"[+] Formatted {name} as ext4")

        # Save in config
        config = load_config()
        config[name] = {"path": str(path)}
        save_config(config)
    except (subprocess.CalledProcessError, OSError) as e:
        print(f"[!] Error creating drive: {e}")
        if path.exists():
            os.remove(path)

def list_drives():
    config = load_config()
    if not config:
        print("[!] No virtual drives found")
        return
    for name, info in config.items():
        status = "mounted" if "loop" in info else "unmounted"
        print(f"{name}: {info['path']} [{status}]")

def mount(name, mount_point):
    if os.geteuid() != 0:
        print("[!] This command requires root privileges.")
        return
    config = load_config()
    if name not in config:
        print(f"[!] Drive {name} not found")
        return

    path = config[name]["path"]
    mount_point = Path(mount_point)

    try:
        mount_point.mkdir(parents=True, exist_ok=True)

        # Find free loop device
        loop_device = subprocess.check_output(["losetup", "-f"]).decode().strip()

        # Attach loop device
        subprocess.run(["losetup", loop_device, path], check=True)
        print(f"DEBUG: Attempting to mount with: mount {loop_device} {str(mount_point)}")
        subprocess.run(["mount", loop_device, str(mount_point)], check=True)
        print(f"[+] Mounted {name} at {mount_point} ({loop_device})")

        config[name]["loop"] = loop_device
        config[name]["mount_point"] = str(mount_point)
        save_config(config)
    except (subprocess.CalledProcessError, OSError) as e:
        print(f"[!] Error mounting drive: {e}")

def unmount(name):
    if os.geteuid() != 0:
        print("[!] This command requires root privileges.")
        return
    config = load_config()
    if name not in config or "loop" not in config[name]:
        print(f"[!] Drive {name} is not mounted")
        return

    loop_device = config[name]["loop"]
    mount_point = config[name]["mount_point"]

    try:
        subprocess.run(["umount", mount_point], check=True)
        subprocess.run(["losetup", "-d", loop_device], check=True)
        print(f"[+] Unmounted {name} from {mount_point}")

        del config[name]["loop"]
        del config[name]["mount_point"]
        save_config(config)
    except (subprocess.CalledProcessError, OSError) as e:
        print(f"[!] Error unmounting drive: {e}")

def delete(name):
    if os.geteuid() != 0:
        print("[!] This command requires root privileges.")
        return
    config = load_config()
    if name not in config:
        print(f"[!] Drive {name} not found")
        return

    if "loop" in config[name]:
        unmount(name)

    path = config[name]["path"]
    try:
        os.remove(path)
        del config[name]
        save_config(config)
        print(f"[+] Deleted virtual drive {name}")
    except OSError as e:
        print(f"[!] Error deleting drive: {e}")

# --- CLI ---
parser = argparse.ArgumentParser(description="Python Virtual Drive Manager")
subparsers = parser.add_subparsers(dest="cmd")

p_create = subparsers.add_parser("create")
p_create.add_argument("name")
p_create.add_argument("size_mb", type=int)

p_list = subparsers.add_parser("list")

p_mount = subparsers.add_parser("mount")
p_mount.add_argument("name")
p_mount.add_argument("mount_point")

p_unmount = subparsers.add_parser("unmount")
p_unmount.add_argument("name")

p_delete = subparsers.add_parser("delete")
p_delete.add_argument("name")

args = parser.parse_args()

if args.cmd == "create":
    create(args.name, args.size_mb)
elif args.cmd == "list":
    list_drives()
elif args.cmd == "mount":
    mount(args.name, args.mount_point)
elif args.cmd == "unmount":
    unmount(args.name)
elif args.cmd == "delete":
    delete(args.name)
else:
    parser.print_help()
