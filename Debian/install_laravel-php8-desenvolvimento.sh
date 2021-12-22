#! /bin/bash
# tem que dar o comandos a seguir antes de rodar o script
# sudo chmod +x install_laravel.sh
# sudo su
###########################################################
#  'Update and Upgrade'
sudo apt update && apt upgrade -y
#  'instala uns programas básicos'
sudo apt install -y wget unzip libpng-dev
sudo apt install -y lsb-release ca-certificates apt-transport-https software-properties-common
#  'adicliona mais lista de pacotes'
sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sudo echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
#  'update novamente'
sudo apt update
#  'instala php 8'
sudo apt upgrade -y && apt -y install php
#  'instala extensions'
sudo apt -y install curl php-mbstring git unzip php8.0-{common,mysql,xml,xmlrpc,curl,gd,imagick,cli,dev,imap,mbstring,opcache,soap,zip,intl,bcmath,ldap,sqlite}
#  'more php' 
sudo apt-get -y install php8.0-sqlite php-xml php-xml unixodbc-dev gnupg
# wrk
#  'COMPOSER'
sudo sh -c "echo 'precedence ::ffff:0:0/96 100' >> /etc/gai.conf"
sudo wget -O composer-setup.php https://getcomposer.org/installer
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer

git clone http://pxl0hosp0811.dispositivos.bb.com.br/fbb/siga.git laravel
cd laravel 
composer install
alias sail='bash vendor/bin/sail'
# ============== instala node
apt-get install- y software-properties-common 
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash - 
apt-get install -y nodejs
npm install
# da permissoes
chown -R 0777 .

apt autoremove -y
cp .env.example .env
sail up -d 
exit
