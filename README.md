# Quick Setup for New Machine

## Prerequisites

- A fresh macOS installation
- Internet connection

## Setup Steps

1. **Download the repository:**

   **Option A: Download as ZIP (no git required):**

   ```bash
   # Download the repository as a ZIP file
   curl -L -o config_files.zip https://github.com/limonadev/config_files/archive/main.zip

   # Extract the ZIP file
   unzip config_files.zip

   # Rename the extracted folder and navigate into it
   mv config_files-main config_files
   cd config_files
   ```

   **Option B: Clone with git (requires Xcode Command Line Tools):**

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
