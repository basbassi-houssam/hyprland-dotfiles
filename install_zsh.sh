#!/bin/bash

# Zsh Plugins Installation Script
# This script installs and configures zsh plugins with Oh My Zsh support

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Zsh Plugins Installation...${NC}"

# Check if running as root (needed for /usr/share/zsh/plugins/)
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}This script must be run as root (sudo) to install plugins to /usr/share/zsh/plugins/${NC}"
  exit 1
fi

# Check if zsh is installed
if ! command -v zsh &>/dev/null; then
  echo -e "${YELLOW}Zsh is not installed. Installing zsh...${NC}"
  apt-get update && apt-get install -y zsh
  # For other package managers, uncomment appropriate line:
  # yum install -y zsh
  # dnf install -y zsh
  # pacman -S --noconfirm zsh
fi

# Function to check if Oh My Zsh is installed
check_oh_my_zsh() {
  local omz_installed=false

  # Check for Oh My Zsh in common locations
  if [ -d "$HOME/.oh-my-zsh" ] || [ -d "/home/$SUDO_USER/.oh-my-zsh" ] || [ -d "/root/.oh-my-zsh" ]; then
    omz_installed=true
  fi

  # Check if oh-my-zsh.sh exists in any user's home
  for possible_home in /home/* /root; do
    if [ -f "$possible_home/.oh-my-zsh/oh-my-zsh.sh" ]; then
      omz_installed=true
      break
    fi
  done

  echo $omz_installed
}

# Ask about Oh My Zsh installation
INSTALL_OMZ=false
OMZ_INSTALLED=$(check_oh_my_zsh)

if [ "$OMZ_INSTALLED" = "true" ]; then
  echo -e "${GREEN}✓ Oh My Zsh is already installed${NC}"
  INSTALL_OMZ=false
else
  echo -e "${YELLOW}Oh My Zsh is not detected.${NC}"
  read -p "Do you want to install Oh My Zsh? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    INSTALL_OMZ=true
  else
    echo -e "${BLUE}Skipping Oh My Zsh installation. Plugins will be installed manually.${NC}"
  fi
fi

# Install Oh My Zsh if requested
install_oh_my_zsh() {
  local target_user=$1
  local user_home=$2

  echo -e "${GREEN}Installing Oh My Zsh for $target_user...${NC}"

  # Run installation as the target user
  if [ "$target_user" = "root" ]; then
    su - root -c 'sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'
  else
    sudo -u "$target_user" sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  fi

  echo -e "${GREEN}Oh My Zsh installed for $target_user${NC}"
}

if [ "$INSTALL_OMZ" = "true" ]; then
  # Determine which user to install for
  if [ "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    USER_HOME="/home/$SUDO_USER"
    USER_NAME="$SUDO_USER"
    echo -e "${BLUE}Installing for user: $USER_NAME${NC}"
    install_oh_my_zsh "$USER_NAME" "$USER_HOME"
  else
    # Ask if installing for root or current user
    echo -e "${YELLOW}Install for which user?${NC}"
    echo "1) Current user ($USER)"
    echo "2) Root"
    echo "3) Specify a different user"
    read -p "Choice (1/2/3): " omz_choice

    case $omz_choice in
    1)
      install_oh_my_zsh "$USER" "$HOME"
      ;;
    2)
      install_oh_my_zsh "root" "/root"
      ;;
    3)
      read -p "Enter username: " custom_user
      if id "$custom_user" &>/dev/null; then
        install_oh_my_zsh "$custom_user" "/home/$custom_user"
      else
        echo -e "${RED}User $custom_user does not exist${NC}"
      fi
      ;;
    *)
      echo -e "${RED}Invalid choice. Skipping Oh My Zsh installation.${NC}"
      ;;
    esac
  fi
fi

# Create plugins directory
PLUGIN_DIR="/usr/share/zsh/plugins"
mkdir -p "$PLUGIN_DIR"

# Function to clone or update a plugin
install_plugin() {
  local repo=$1
  local dest=$2
  local name=$3

  if [ -d "$dest" ]; then
    echo -e "${YELLOW}Updating $name...${NC}"
    (cd "$dest" && git pull)
  else
    echo -e "${GREEN}Installing $name...${NC}"
    git clone "$repo" "$dest"
  fi
}

# Install fzf-tab
install_plugin "https://github.com/Aloxaf/fzf-tab.git" "$PLUGIN_DIR/fzf-tab-git" "fzf-tab"

# Install zsh-autosuggestions
install_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "$PLUGIN_DIR/zsh-autosuggestions" "zsh-autosuggestions"

# Install zsh-syntax-highlighting
install_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$PLUGIN_DIR/zsh-syntax-highlighting" "zsh-syntax-highlighting"

# Install zsh-history-substring-search
install_plugin "https://github.com/zsh-users/zsh-history-substring-search.git" "$PLUGIN_DIR/zsh-history-substring-search" "zsh-history-substring-search"

# Function to add plugin sources to .zshrc
configure_zshrc() {
  local zshrc_file=$1
  local user_name=$2

  if [ ! -f "$zshrc_file" ]; then
    # Create basic .zshrc if it doesn't exist
    echo "# Created by zsh plugin installer" >"$zshrc_file"
    echo "export ZSH=\"\$HOME/.oh-my-zsh\" if [ -f \"\$HOME/.oh-my-zsh/oh-my-zsh.sh\" ]; then" >>"$zshrc_file"
    echo "  source \"\$HOME/.oh-my-zsh/oh-my-zsh.sh\"" >>"$zshrc_file"
    echo "fi" >>"$zshrc_file"
  fi

  # Check if plugins are already sourced
  if ! grep -q "fzf-tab-git" "$zshrc_file"; then
    echo -e "\n# Zsh Plugins Configuration" >>"$zshrc_file"

    # If Oh My Zsh is present, add plugins to the plugins array
    if [ -f "$(dirname "$zshrc_file")/.oh-my-zsh/oh-my-zsh.sh" ] || [ "$INSTALL_OMZ" = "true" ]; then
      echo -e "${GREEN}Configuring plugins for Oh My Zsh...${NC}"
      # Backup existing plugins line if present
      if grep -q "^plugins=(" "$zshrc_file"; then
        sed -i.bak 's/^plugins=(/plugins=(fzf-tab zsh-autosuggestions zsh-syntax-highlighting history-substring-search /' "$zshrc_file"
      else
        echo "plugins=(fzf-tab zsh-autosuggestions zsh-syntax-highlighting history-substring-search)" >>"$zshrc_file"
      fi
    fi

    # Always add source lines for manual loading
    echo "" >>"$zshrc_file"
    echo "# Manual plugin loading (fallback)" >>"$zshrc_file"
    echo "source /usr/share/zsh/plugins/fzf-tab-git/fzf-tab.zsh 2>/dev/null" >>"$zshrc_file"
    echo "source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh 2>/dev/null" >>"$zshrc_file"
    echo "source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh 2>/dev/null" >>"$zshrc_file"
    echo "source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh 2>/dev/null" >>"$zshrc_file"

    # Additional configuration for plugins
    echo "" >>"$zshrc_file"
    echo "# Plugin Settings" >>"$zshrc_file"
    echo "# History Substring Search bindings" >>"$zshrc_file"
    echo "bindkey '^[[A' history-substring-search-up" >>"$zshrc_file"
    echo "bindkey '^[[B' history-substring-search-down" >>"$zshrc_file"
    echo "bindkey '^P' history-substring-search-up" >>"$zshrc_file"
    echo "bindkey '^N' history-substring-search-down" >>"$zshrc_file"

    echo -e "${GREEN}Configured $zshrc_file${NC}"
  else
    echo -e "${YELLOW}Plugins already configured in $zshrc_file${NC}"
  fi
}

# Configure system-wide zshrc
ZSHRC_SYSTEM="/etc/zsh/zshrc"
if [ -f "$ZSHRC_SYSTEM" ] || [ ! -f "/etc/skel/.zshrc" ]; then
  configure_zshrc "$ZSHRC_SYSTEM" "system"
fi

# Configure user .zshrc files
configure_for_user() {
  local user_home=$1
  local user_name=$2
  local user_zshrc="$user_home/.zshrc"

  if [ -d "$user_home" ] && [ "$user_home" != "/" ]; then
    if [ -f "$user_zshrc" ] || [ ! -f "/etc/skel/.zshrc" ]; then
      configure_zshrc "$user_zshrc" "$user_name"
      chown "$user_name":"$user_name" "$user_zshrc" 2>/dev/null || true
    fi
  fi
}

# Configure for root if exists
if [ -d "/root" ]; then
  configure_zshrc "/root/.zshrc" "root"
fi

# Configure for the sudo user if exists
if [ "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
  configure_for_user "/home/$SUDO_USER" "$SUDO_USER"
fi

# Configure for all users with home directories
echo -e "${BLUE}Checking for other users...${NC}"
for user_home in /home/*; do
  if [ -d "$user_home" ]; then
    username=$(basename "$user_home")
    if [ "$username" != "$SUDO_USER" ] && [ "$username" != "lost+found" ]; then
      read -p "Configure plugins for user '$username'? (y/n): " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        configure_for_user "$user_home" "$username"
      fi
    fi
  fi
done

# Create template for new users
echo -e "${GREEN}Creating template for new users...${NC}"
configure_zshrc "/etc/skel/.zshrc" "skel"

# Set proper permissions
chmod -R 755 "$PLUGIN_DIR"

# Summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Installed plugins:"
echo -e "  ✓ fzf-tab"
echo -e "  ✓ zsh-autosuggestions"
echo -e "  ✓ zsh-syntax-highlighting"
echo -e "  ✓ zsh-history-substring-search"

if [ "$INSTALL_OMZ" = "true" ]; then
  echo -e "\n${GREEN}✓ Oh My Zsh has been installed${NC}"
elif [ "$OMZ_INSTALLED" = "true" ]; then
  echo -e "\n${GREEN}✓ Oh My Zsh detected and configured${NC}"
else
  echo -e "\n${YELLOW}⚠ Oh My Zsh not installed (you chose to skip)${NC}"
  echo -e "Plugins are configured to work without Oh My Zsh"
fi

echo -e "\n${YELLOW}To use these plugins:${NC}"
echo -e "1. Start a new zsh session, or"
echo -e "2. Run: ${GREEN}source ~/.zshrc${NC}"
echo -e "3. If zsh is not your default shell, run: ${GREEN}chsh -s $(which zsh)${NC}"

echo -e "\n${BLUE}Note:${NC} If using Oh My Zsh, the plugins are added to the plugins array."
echo -e "You can verify this in your ~/.zshrc file."

echo -e "\n${YELLOW}Optional - Add these to your ~/.zshrc for better performance:${NC}"
echo -e "  # Speed up plugin loading"
echo -e "  ZSH_DISABLE_COMPFIX=true"

# Optional: Make zsh the default shell
read -p "Do you want to set zsh as your default shell? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  if [ "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    chsh -s "$(which zsh)" "$SUDO_USER"
    echo -e "${GREEN}Zsh set as default shell for $SUDO_USER${NC}"
  else
    chsh -s "$(which zsh)"
    echo -e "${GREEN}Zsh set as default shell${NC}"
  fi
  echo -e "${YELLOW}You may need to log out and back in for changes to take effect.${NC}"
fi
