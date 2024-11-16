#!/bin/sh

set -e

if [ "$(id -u)" = 0 ]; then
    printf '\033[31;1m'
    printf 'Installation script must not be run as root!'
    exit 1;
fi

# sudo access will be requested if the script was not run with sudo or under root user
sudo -k

# This causes the following error: ubuntu_18.04.sh: 24: [: =: unexpected operator
# Need to fix it, but the things work fine
if ! [ "$(sudo id -u)" = 0 ]; then
    printf '\033[31;1m'
    printf 'Root password was not entered correctly!'
    exit 1;
fi

sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y

# Remove all custom app source lists. You must add them back manually if needed.
    printf '\n>>> Removing all custom repository sources! >>>\n'
# Remove al files except `/etc/apt/sources.list.d/ubuntu.sources*`
sudo find /etc/apt/sources.list.d/ -type f -not -name 'ubuntu.sources*' -exec rm -f {} \;

    printf '\n>>> Creating files and folders... >>>\n'
# "db" for dumps and "certs" for SSL certificates
mkdir -p ~/misc/apps ~/misc/certs ~/misc/db

# Install cUrl
    printf '\n>>> cUrl is going to be installed >>>\n'
sudo apt install curl -y

    printf '\n>>> Adding repositories and updating software list >>>\n'
# Various PHP versions
sudo add-apt-repository ppa:ondrej/php -y

# Add VirtualBox repository
    printf '\n>>> Adding VirtualBox repository >>>\n'
if ! test -f /etc/apt/trusted.gpg.d/oracle_vbox_2016.gpg ; then
    wget -qO - https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/oracle_vbox_2016.gpg
fi
echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list

    printf '\n>>> Running Ubuntu upgrade >>>\n'
sudo apt update
sudo apt upgrade -y
# ifconfig since 18.04
sudo apt install net-tools -y

    printf '\n>>> Zsh, Oh My Zsh, Powerlevel10k theme and Git are going to be installed >>>\n'
# Cleanup previous Zsh installation if exists
if test -f ~/.zshrc ; then
    mv ~/.zshrc ~/zshrc-"$(date +%Y-%m-%d_%H-%M)"
fi
sudo apt purge zsh -y
rm -rf ~/.oh-my-zsh/ ~/.zshrc ~/.p10k.zsh
# Install Zsh and Git
sudo apt install zsh git wget -y
# Install Oh My Zsh (unattended)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
# Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
# Set Powerlevel10k as the default Oh My Zsh theme
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
# Clone the preconfigured .p10k.zsh file
wget -qO ~/.p10k.zsh https://raw.githubusercontent.com/maksymz/ubuntu_post_install_scripts/main/p10k.zsh
chown $USER:$USER ~/.p10k.zsh
# Ensure .zshrc sources .p10k.zsh
grep -qxF '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' ~/.zshrc || \
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> ~/.zshrc
# Install Meslo Nerd Fonts
mkdir -p ~/.local/share/fonts
wget -nc -P ~/.local/share/fonts \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf \
  https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf
# Refresh font cache
fc-cache -fv ~/.local/share/fonts/
# Change default shell to Zsh without asking for password
if grep -q "$(which zsh)" /etc/shells ; then
    sudo usermod --shell "$(which zsh)" "$USER"
fi
    printf '\n>>> Zsh, Oh My Zsh, Powerlevel10k theme and Git are installed >>>\n'

# Install Guake
    printf '\n>>> Guake terminal is going to be installed >>>\n'
    printf '\nAdd a custom shortcut for "guake-toggle": https://askubuntu.com/questions/1406716/function-keys-not-working-at-desktop-on-ubuntu-22-04\n'
sudo apt install guake -y

# Install Sublime Text editor
    printf '\n>>> Sublime Text is going to be installed >>>\n'
sudo snap install sublime-text --classic

# Install Midnight Commander
    printf '\n>>> Midnight Commander is going to be installed >>>\n'
sudo apt install mc -y

# Install Vim text editor
    printf '\n>>> Vim is going to be installed >>>\n'
sudo apt install vim -y

# Install htop utility
    printf '\n>>> htop is going to be installed >>>\n'
sudo apt install htop -y

# Install Git and Git Gui
    printf '\n>>> Git and Git Gui are going to be installed >>>\n'
sudo apt install git git-gui -y

# Install Docker: based on https://docs.docker.com/engine/install/ubuntu/
    printf '\n>>> Docker is going to be installed >>>\n'
# Stop docker socket activation services before uninstalling. Otherwise, it will fail on start when we reinstall the software
sudo systemctl stop docker.socket || true
sudo apt purge docker* -y
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt remove -y $pkg; done
# Add Docker's official GPG key:
sudo apt install ca-certificates -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
# Install Docker Engine:
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
sudo systemctl start docker
sudo systemctl start containerd
# This is to execute Docker command without sudo. Will work after logout/login because permissions should be refreshed
sudo groupadd docker || true
sudo usermod -aG docker "${USER}"

export DOCKERIZER_PROJECTS_ROOT_DIR=${HOME}/misc/apps/
export DOCKERIZER_SSL_CERTIFICATES_DIR=${HOME}/misc/certs/

# NVM (Node Version Manager) and NPM 22
# NodeJS is needed to run JSCS and ESLint for Magento2 in PHPStorm
    printf '\n>>> NVM (Node Version Manager) and NPM 22 are going to be installed >>>\n'
sudo apt purge nodejs -y
rm -rf ~/.nvm/
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
# We don't know whether this is first install with Bash or we use Zsh, so we need to add NVM vars in order to run it
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 22
# shellcheck disable=SC2016
printf '\nexport NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion' >> ~/.zshrc

# Add aliases and env variables BEFORE we install projects that use them
    printf '\n>>> Creating aliases and enabling color output >>>\n'
# shellcheck disable=SC2028
echo "
# PHP xDebug 3.x config
export XDEBUG_SESSION=PHPSTORM

# === Mandatory Dockerizer variables ===
export DOCKERIZER_PROJECTS_ROOT_DIR=\${HOME}/misc/apps/
export DOCKERIZER_SSL_CERTIFICATES_DIR=\${HOME}/misc/certs/

# === Show a list of Docker containers and their composition locations ===
COMPOSITIONS() {
    local info='{{.Label \"com.docker.compose.project\"}}\t{{.Label \"com.docker.compose.service\"}}\t{{.Status}}\t{{.Names}}\t{{.Label \"com.docker.compose.project.working_dir\"}}'

    docker container ls --all --filter label=com.docker.compose.project --format \"table \$info\"
}

# === docker compose aliases ===
alias DOWN='docker compose -f docker-compose.yaml -f docker-compose-dev-tools.yaml down'
alias DOWNV='docker compose -f docker-compose.yaml -f docker-compose-dev-tools.yaml down --volumes'
alias PS='docker compose -f docker-compose.yaml -f docker-compose-dev-tools.yaml ps'
alias RESTART='docker compose -f docker-compose.yaml -f docker-compose-dev-tools.yaml restart'
alias START='docker compose -f docker-compose.yaml -f docker-compose-dev-tools.yaml start'
alias STOP='docker compose -f docker-compose.yaml -f docker-compose-dev-tools.yaml stop'
alias UP='docker compose -f docker-compose.yaml -f docker-compose-dev-tools.yaml up -d --force-recreate'

# === Dockerizer 3.2 aliases ===
# Path to Dockerizer to make other aliases shorter
alias DOCKERIZER='php -d xdebug.start_with_request=trigger \${DOCKERIZER_PROJECTS_ROOT_DIR}dockerizer_for_php/bin/dockerizer'
# Compositions
alias BUILD='DOCKERIZER composition:build-from-template'
# Magento
alias SETUP='DOCKERIZER magento:setup'
alias REINSTALL='DOCKERIZER magento:reinstall'
# MySQL
alias CONNECT='DOCKERIZER docker:mysql:connect -c \$(DOCKERIZER composition:get-container-name mysql)'
alias IMPORTDB='DOCKERIZER docker:mysql:import-db -c \$(DOCKERIZER composition:get-container-name mysql)'
alias EXPORTDB='DOCKERIZER docker:mysql:export-db -c \$(DOCKERIZER composition:get-container-name mysql)'

# === Enter Docker containers ===
alias PHP='docker exec -it \$(DOCKERIZER composition:get-container-name php) bash'
alias PHPROOT='docker exec -uroot -it \$(DOCKERIZER composition:get-container-name php) bash'

# === PHP container aliases ===
alias CI='docker exec -it \$(DOCKERIZER composition:get-container-name php) composer install'

# === Magento aliases ===
alias MAGENTO='docker exec -it \$(DOCKERIZER composition:get-container-name php) php bin/magento'
alias CC='MAGENTO cache:clean'
alias CF='MAGENTO cache:flush'
alias IR='MAGENTO indexer:reindex'
alias SU='MAGENTO setup:upgrade'
alias SDC='MAGENTO setup:di:compile'
alias URN='MAGENTO dev:urn-catalog:generate .idea/misc.xml; sed -i \"s/\/var\/www\/html/\\\$PROJECT_DIR\\\$/g\" ../../.idea/misc.xml'
alias MODEDEV='MAGENTO deploy:mode:set developer'
alias MODEDEF='MAGENTO deploy:mode:set default'
alias MODEPROD='MAGENTO deploy:mode:set production'

alias CR='rm -rf var/cache/* var/page_cache/* var/view_preprocessed/* var/di/* var/generation/* generated/code/* generated/metadata/* pub/static/frontend/* pub/static/adminhtml/* pub/static/deployed_version.txt'
alias MCS='php -d xdebug.start_with_request=trigger \${DOCKERIZER_PROJECTS_ROOT_DIR}magento-coding-standard/vendor/bin/phpcs --standard=Magento2 --severity=1 '
alias MND='php -d xdebug.start_with_request=trigger \${DOCKERIZER_PROJECTS_ROOT_DIR}php-quality-tools/vendor/bin/phpmnd '" >> ~/.zshrc

# Install PHP common packages
    printf '\n>>> PHP 8.3 and common modules are going to be installed >>>\n'
sudo apt purge php* -y
sudo rm -rf /etc/php/ || true
sudo apt install \
    php8.3-bz2 \
    php8.3-cli \
    php8.3-common \
    php8.3-curl \
    php8.3-intl \
    php8.3-mbstring \
    php8.3-mysql \
    php8.3-opcache \
    php8.3-readline \
    php8.3-ssh2 \
    php8.3-xml \
    php8.3-xdebug \
    php8.3-zip \
    --no-install-recommends -y
sudo apt remove composer -y
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php
php -r "unlink('composer-setup.php');"
sudo mv composer.phar /usr/bin/composer

    printf '\n>>> Creating ini files for the development environment >>>\n'
IniDirs='/etc/php/*/*/conf.d/'
for IniDir in ${IniDirs};
do
    printf 'Creating %s999-custom-config.ini\n' "${IniDir}"
    sudo rm -f "${IniDir}"999-custom-config.ini || true
    printf 'error_reporting=E_ALL & ~E_DEPRECATED
display_errors=On
display_startup_errors=On
ignore_repeated_errors=On
cgi.fix_pathinfo=1
max_execution_time=3600
session.gc_maxlifetime=84600

opcache.enable=1
opcache.validate_timestamps=1
opcache.revalidate_freq=1
opcache.max_wasted_percentage=10
opcache.memory_consumption=256
opcache.max_accelerated_files=20000

xdebug.mode=debug
xdebug.remote_handler=dbgp
xdebug.discover_client_host=0
xdebug.show_error_trace=1
xdebug.start_with_request=yes
xdebug.max_nesting_level=256
xdebug.log_level=0\n' | sudo tee "${IniDir}"999-custom-config.ini > /dev/null
done

IniDirs='/etc/php/*/cli/conf.d/'
for IniDir in ${IniDirs};
do
    printf 'memory_limit=2G\n' | sudo tee -a "${IniDir}"999-custom-config.ini >> /dev/null
done

    printf '\n>>> Enabling php modules: xdebug >>>\n'
sudo phpenmod xdebug

# Install a tool for PHP projects dockerization and fast Magento installation
    printf '\n>>> Installing Dockerizer for PHP tool - https://github.com/DefaultValue/dockerizer_for_php >>>\n'
if ! test -d "${DOCKERIZER_PROJECTS_ROOT_DIR}"dockerizer_for_php; then
    cd "${DOCKERIZER_PROJECTS_ROOT_DIR}"
    git clone https://github.com/DefaultValue/dockerizer_for_php.git
fi

cd "${DOCKERIZER_PROJECTS_ROOT_DIR}"dockerizer_for_php/
git config core.fileMode false
git reset --hard HEAD
git pull origin master --no-rebase
composer install

    printf '\n>>> Create a Docker container with Traefik to works as a reverse-proxy between host OS and Docker compositions >>>\n'
# @TODO: backup the `certificates.toml` file and fully reinstall this composition
if ! test -d "${DOCKERIZER_PROJECTS_ROOT_DIR}"traefik-reverse-proxy; then
    cd "${DOCKERIZER_PROJECTS_ROOT_DIR}"
    mkdir ./traefik-reverse-proxy
    cd ./traefik-reverse-proxy/
    php "${DOCKERIZER_PROJECTS_ROOT_DIR}"dockerizer_for_php/bin/dockerizer composition:build-from-template \
        --template=traefik --required-services=traefik_host_network
    mv ./.dockerizer/reverse-proxy/* ./
    rm -rf ./.dockerizer/
    printf '\nDOCKERIZER_TRAEFIK_SSL_CONFIGURATION_FILE=%straefik-reverse-proxy/traefik/configuration/certificates.toml' "${DOCKERIZER_PROJECTS_ROOT_DIR}" >> "${DOCKERIZER_PROJECTS_ROOT_DIR}"dockerizer_for_php/.env.local
fi

cd "${DOCKERIZER_PROJECTS_ROOT_DIR}"traefik-reverse-proxy/
sudo su -c "export DOCKERIZER_SSL_CERTIFICATES_DIR=$DOCKERIZER_SSL_CERTIFICATES_DIR ; docker compose up -d --force-recreate"

# Allow Dockerizer to write to `/etc/hosts` without asking for password
# This is unsafe, but better than keeping the root password in a plain text file
sudo setfacl -m "${USER}":rw /etc/hosts
# Append Traefik Dashboard domain to `/etc/hosts`
if ! grep -q '127.0.0.1 traefik.docker.local' /etc/hosts; then
    printf '\n127.0.0.1 traefik.docker.local' | tee -a /etc/hosts
fi

# Install VirtualBox from the repository.
# 2020-04-29: Current version is 6.1 (latest one)
    printf '\n>>> VirtualBox are going to be installed >>>\n'
sudo apt purge virtualbox -y
sudo apt install virtualbox-7.1 -y
    printf '\n>>> Adding VirtualBox user to your group, so it can access USB devices >>>\n'
sudo usermod -aG vboxusers "${USER}"

# Install Google Chrome
    printf '\n>>> Google Chrome is going to be installed >>>\n'
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# Install mkcert - https://github.com/FiloSottile/mkcert/releases
    printf '\n>>> Mkcert is going to be installed -https://github.com/FiloSottile/mkcert >>>\n'
sudo apt install libnss3-tools -y
sudo wget https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64
sudo chmod +x mkcert-v1.4.4-linux-amd64
sudo mv mkcert-v1.4.4-linux-amd64 /usr/bin/mkcert
mkcert -install

# Install Shutter
    printf '\n>>> Shutter is going to be installed >>>\n'
sudo apt purge shutter -y
# Shutter may still not work with Wayland, but can be used to easily edit screenshots in Ubuntu 22.04
sudo apt install shutter -y

# Install Diodon clipboard manager because clipit is broken for now :(
    printf '\n>>> Diodon clipboard manager is going to be installed >>>\n'
sudo apt install diodon -y

# Install Slack messenger
    printf '\n>>> Slack messenger is going to be installed >>>\n'
sudo snap install slack

# Install PHPStorm
    printf '\n>>> PHPStorm is going to be installed >>>\n'
sudo snap install phpstorm --classic
if ! grep -q 'fs.inotify.max_user_watches = 524288' /etc/sysctl.conf; then
    printf '\n>>> Setting filesystem parameters for PHPStorm IDE: fs.inotify.max_user_watches = 524288 >>>\n'
    echo 'fs.inotify.max_user_watches = 524288' | sudo tee -a /etc/sysctl.conf > /dev/null
fi

# Install Gnome Tweak Tool for tuning Ubuntu
    printf '\n>>> Gnome Tweak Tool is going to be installed >>>\n'
sudo apt install gnome-tweaks -y

    printf '\n>>> Magento 2 coding standards - https://github.com/magento/magento-coding-standard >>>\n'
if ! test -d "${DOCKERIZER_PROJECTS_ROOT_DIR}"magento-coding-standard; then
    cd "${DOCKERIZER_PROJECTS_ROOT_DIR}"
    git clone https://github.com/magento/magento-coding-standard.git
fi
cd "${DOCKERIZER_PROJECTS_ROOT_DIR}"magento-coding-standard/
git config core.fileMode false
git reset --hard HEAD
git checkout master
git pull origin master --no-rebase
composer install
npm install

    printf '\n>>> Install PHPMD (Mess Detector), PHPStan (Static Analysis Tool) and PHPMND (Magic Number Detector) >>>\n'
if ! test -d "${DOCKERIZER_PROJECTS_ROOT_DIR}"php-quality-tools; then
    mkdir "${DOCKERIZER_PROJECTS_ROOT_DIR}"php-quality-tools
fi

cd "${DOCKERIZER_PROJECTS_ROOT_DIR}"php-quality-tools/
rm -rf ./*
rm -rf ./.* || true
echo '{
    "require-dev": {
        "squizlabs/php_codesniffer": "^3.7",
        "phpstan/phpstan": "^2.0",
        "vimeo/psalm": "^5.26",
        "phpmd/phpmd": "^2.15",
        "povils/phpmnd": "^3.5"
    }
}' > composer.json
composer install

# File template to allow creating new documents from the context menu
touch ~/Templates/Untitled

# Cleanup unneeded packages
sudo apt autoremove -y

# System reboot
printf '\033[31;1m/**********************
*
*    ATTENTION!
*
*    System is going to be restarted
*
*    More information is in the repositories:
*    - Ubuntu post-install scripts - https://github.com/DefaultValue/ubuntu_post_install_scripts
*    - Dockerizer projects - https://github.com/DefaultValue/dockerizer_for_php
*    - Development infrastructure - https://github.com/DefaultValue/docker_infrastructure
*    (open and save the URL to bookmarks)
*
*    PRESS ANY KEY TO CONTINUE
*
\**********************
'
read -r REBOOT_VARIABLE

printf '\n*** Job done! Going to reboot in 5 seconds... ***\n'

sleep 5
sudo reboot