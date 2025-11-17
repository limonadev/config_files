# Quick Setup for New Machine

## Prerequisites

- A fresh macOS installation
- Internet connection

## Setup Steps

1. **Clone the repository from GitHub:**

   ```bash
   git clone https://github.com/limonadev/config_files.git
   cd config_files
   ```

2. **Run the setup script:**

   ```bash
   zsh setup.sh
   ```

   Or make it executable first:

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. **After the script completes:**
   - Restart your terminal to see the font changes
   - If you generated an SSH key, add it to GitHub: https://github.com/settings/keys
   - Install JetBrains Toolbox manually (if needed) and uncomment the line in `.zprofile`

## Notes

- The script can be run from any location - it automatically finds config files relative to itself
- All configuration files are copied from the repository to your home directory
- SSH keys are generated automatically if they don't exist
- Cursor extensions are installed from `cursor/extensions.txt`
