#! /bin/bash
# tem que dar o comandos a seguir antes de rodar o script
# sudo chmod +x install_laravel.sh
# sudo su
###########################################################
#  'Update and Upgrade'
apt update && apt upgrade -y
#  'instala uns programas básicos'
apt -y install lsb-release apt-transport-https ca-certificates wget redis-server nginx unzip
#  'adicliona mais lista de pacotes'
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
#  'update novamente'
apt update
#  'instala php 7.4'
apt upgrade -y && apt -y install php7.4
#  'instala extensions'
apt -y install curl php-mbstring git unzip php7.4-{common,mysql,xml,xmlrpc,curl,gd,imagick,cli,dev,imap,mbstring,opcache,soap,zip,intl,bcmath,ldap,sqlite}
#  'more php' 
apt-get -y install php7.4-sqlite php-xml php7.0-xml wrk unixodbc-dev supervisor
#  'COMPOSER'
sh -c "echo 'precedence ::ffff:0:0/96 100' >> /etc/gai.conf"
wget -O composer-setup.php https://getcomposer.org/installer
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
# Instala sqlserver drives
apt-get install curl apt-transport-https
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
apt-get update
sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
pecl install sqlsrv
pecl install pdo_sqlsrv
phpenmod sqlsrv pdo_sqlsrv
# adiciona sqlserver drives nas extensions do php
bash -c 'printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/7.4/mods-available/sqlsrv.ini'
bash -c 'printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/7.4/mods-available/pdo_sqlsrv.ini'
# Instala Swoole
pecl channel-update pecl.php.net && pecl install swoole
# Adiciona swoolenas extensions do php
bash -c 'echo "extension=swoole.so" >> /etc/php/7.4/cli/php.ini'
# Instala Redis
service redis-server start
# Instala Laravel
cd /var/www/
composer create-project --no-interaction --prefer-dist laravel/laravel laravel
cd laravel 
composer require swooletw/laravel-swoole -n
bash -c 'echo "SWOOLE_HTTP_DAEMONIZE=true" >> .env'
chown -R :www-data /var/www/laravel/storage/
chown -R :www-data /var/www/laravel/bootstrap/cache/
chmod -R 0777 /var/www/laravel/storage/
chmod -R 0775 /var/www/laravel/bootstrap/cache/
chown -R www-data.www-data /var/www/laravel/storage
chown -R www-data.www-data /var/www/laravel/bootstrap/cache
mkdir -p /var/www/laravel
php artisan swoole:http start
# Configura nginx
# Alterar o caminhho aqui
cd /home/mateus 
rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
rm -rf /var/www/html
cp laravel /etc/nginx/sites-available/laravel
ln -s /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/laravel
service nginx restart
# Instalando e criando supervisor para laravel
apt-get install supervisor
bash -c 'printf "[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/larave/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=root
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/laravel/storage/logs/worker.log
stopwaitsecs=3600" > /etc/supervisor/conf.d/laravel-worker.conf'
service supervisor start
# Lembrar de alterar o usuário no final do comando
bash -c 'echo "* * * * * /var/www/laravel && php artisan schedule:run >> /dev/null 2>&1" >>  /var/spool/cron/crontabs/mateus'
service cron start
apt autoremove -y
exit