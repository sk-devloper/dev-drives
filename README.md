# dev-drives: Python Virtual Drive Manager

`dev-drives` is a command-line tool written in Python for managing virtual disk images. It allows users to create, format, mount, unmount, and delete virtual drives, primarily for development or testing purposes.

## Features

*   **Create:** Generate a virtual disk image of a specified size.
*   **Format:** Automatically formats new virtual drives with the `ext4` filesystem.
*   **Mount:** Mount a virtual drive to a specified directory.
*   **Unmount:** Unmount a previously mounted virtual drive.
*   **Delete:** Remove a virtual drive image file.
*   **List:** Display all managed virtual drives and their current status.

## Installation

This project requires Python 3 and several system utilities.

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/your-username/dev-drives.git
    cd dev-drives
    ```

2.  **Install system dependencies:**
    `dev-drives` relies on `mkfs.ext4`, `losetup`, `mount`, and `umount`. Ensure these are installed on your system. On Debian/Ubuntu-based systems, you can install them with:
    ```bash
    sudo apt update
    sudo apt install util-linux e2fsprogs
    ```

3.  **Python Dependencies:**
    Currently, there are no external Python dependencies beyond the standard library.

## Usage

All commands require root privileges to perform operations like creating, mounting, or deleting virtual drives.

```bash
sudo python3 main.py <command> [arguments]
```

### Commands:

*   **`create <name> <size_mb>`**
    Creates a new virtual drive image.
    *   `<name>`: A unique name for your virtual drive (e.g., `mydevdrive`).
    *   `<size_mb>`: The size of the virtual drive in megabytes (e.g., `1024` for 1GB).
    ```bash
    sudo python3 main.py create mydevdrive 1024
    ```

*   **`list`**
    Lists all virtual drives managed by `dev-drives`.
    ```bash
    sudo python3 main.py list
    ```

*   **`mount <name> <mount_point>`**
    Mounts a virtual drive to a specified directory.
    *   `<name>`: The name of the virtual drive to mount.
    *   `<mount_point>`: The absolute path to the directory where the drive will be mounted (e.g., `/mnt/mydata`). The directory will be created if it doesn't exist.
    ```bash
    sudo python3 main.py mount mydevdrive /mnt/mydata
    ```

*   **`unmount <name>`**
    Unmounts a virtual drive.
    *   `<name>`: The name of the virtual drive to unmount.
    ```bash
    sudo python3 main.py unmount mydevdrive
    ```

*   **`delete <name>`**
    Deletes a virtual drive image file. If the drive is mounted, it will be unmounted first.
    *   `<name>`: The name of the virtual drive to delete.
    ```bash
    sudo python3 main.py delete mydevdrive
    ```

## Configuration

`dev-drives` stores its configuration (details about created virtual drives) in a JSON file located at `~/.vdrive.json`. This file is automatically managed by the script.

## Security Considerations

**WARNING:** This tool requires `sudo` (root privileges) for most of its operations. Running commands with root privileges carries inherent risks.

*   **Command Injection:** The current implementation does not sanitize user inputs (`name`, `mount_point`) before passing them to `subprocess.run`. This makes the tool potentially vulnerable to command injection if malicious input is provided. **It is strongly advised not to use this tool with untrusted input.**
*   **Privilege Escalation:** The script runs entirely as root for operations. A more secure approach would involve privilege separation, where root privileges are dropped after necessary operations.

## Future Improvements

*   **Input Sanitization:** Implement robust input validation and sanitization to prevent command injection.
*   **Improved Error Handling:** Enhance error handling for system commands and edge cases (e.g., `losetup -f` failure, mount point already in use).
*   **Logging:** Replace `print` statements with Python's `logging` module for better diagnostics.
*   **Testing:** Add unit and integration tests to ensure reliability and prevent regressions.
*   **Configuration Flexibility:** Allow the configuration file path to be user-configurable.
*   **Privilege Separation:** Explore ways to minimize the duration and scope of root privileges.
*   **Support for other filesystems:** Extend functionality to support other filesystems like XFS, Btrfs, etc.
*   **Progress Indicators:** Add progress indicators for long-running operations like drive creation.