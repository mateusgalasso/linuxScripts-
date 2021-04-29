#! /bin/bash
# tem que dar o comandos a seguir antes de rodar o script
# sudo chmod +x install_laravel.sh
# sudo su
###########################################################
#  'Update and Upgrade'
apt update && apt upgrade -y
#  'instala uns programas básicos'
apt -y install lsb-release apt-transport-https ca-certificates wget redis-server nginx unzip libcurl4-openssl-dev
#  'adicliona mais lista de pacotes'
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
#  'update novamente'
apt update
#  'instala php 8'
apt upgrade -y && apt -y install php
#  'instala extensions'
apt -y install curl php-mbstring git unzip php8.0-{common,mysql,xml,xmlrpc,curl,gd,imagick,cli,dev,imap,mbstring,opcache,soap,zip,intl,bcmath,ldap,sqlite,fpm}
#  'more php' 
apt-get -y install php8.0-sqlite php-xml php-xml wrk unixodbc-dev supervisor
#  'COMPOSER'
sh -c "echo 'precedence ::ffff:0:0/96 100' >> /etc/gai.conf"
wget -O composer-setup.php https://getcomposer.org/installer
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
# Instala Redis
service redis-server start
# Instala Laravel
cd /var/www/
composer create-project --no-interaction --prefer-dist laravel/laravel laravel
# da permissoes
chown -R :www-data /var/www/laravel/storage/
chown -R :www-data /var/www/laravel/bootstrap/cache/
chmod -R 0777 /var/www/laravel/storage/
chmod -R 0775 /var/www/laravel/bootstrap/cache/
chown -R www-data.www-data /var/www/laravel/storage
chown -R www-data.www-data /var/www/laravel/bootstrap/cache
mkdir -p /var/www/laravel

# Configura nginx
service nginx stop
rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
rm -rf /var/www/html
cp /home/mateus/laravel.conf /etc/nginx/sites-available/laravel.conf
ln -s /etc/nginx/sites-available/laravel.conf /etc/nginx/sites-enabled/

# Inicia php fpm
# sudo systemctl start php8.0-fpm
# sudo systemctl enable php8.0-fpm
sudo service php8.0-fpm start
sudo update-rc.d php8.0-fpm defaults
sudo update-rc.d php8.0-fpm enable

# Instalando e criando supervisor para laravel
apt-get install supervisor

# Queue workers
bash -c 'printf "[program:laravel-worker]
process_name=laravel_worker
command=php /var/www/laravel/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=root
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/laravel/storage/logs/worker.log
stopwaitsecs=3600" > /etc/supervisor/conf.d/laravel-worker.conf'

# Lembrar de alterar o usuário no final do comando
bash -c 'echo "* * * * * /var/www/laravel && php artisan schedule:run >> /dev/null 2>&1" >>  /var/spool/cron/crontabs/mateus'
service cron start
apt autoremove -y

# Adiciona algumas coisas no supervisor
sudo touch /var/run/supervisor.sock
sudo chmod 777 /var/run/supervisor.sock
echo_supervisord_conf > /etc/supervisord.conf
sudo supervisord -c /etc/supervisord.conf

# # Instala systemctl para o wls2
# git clone https://github.com/DamionGans/ubuntu-wsl2-systemd-script.git
# cd ubuntu-wsl2-systemd-script/
# bash ubuntu-wsl2-systemd-script.sh
# Inicia servicos
# sudo systemctl start supervisor
# sudo systemctl enable supervisor
sudo service supervisor start
sudo update-rc.d supervisor defaults
sudo update-rc.d supervisor enable
# sudo systemctl start nginx
# sudo systemctl enable nginx
sudo service nginx start
sudo update-rc.d nginx defaults
sudo update-rc.d nginx enable
exit