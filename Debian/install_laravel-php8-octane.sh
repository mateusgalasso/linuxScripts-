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
apt -y install curl php-mbstring git unzip php8.0-{common,mysql,xml,xmlrpc,curl,gd,imagick,cli,dev,imap,mbstring,opcache,soap,zip,intl,bcmath,ldap,sqlite}
#  'more php' 
apt-get -y install php8.0-sqlite php-xml php-xml wrk unixodbc-dev supervisor
# wrk
#  'COMPOSER'
sh -c "echo 'precedence ::ffff:0:0/96 100' >> /etc/gai.conf"
wget -O composer-setup.php https://getcomposer.org/installer
php composer-setup.php --install-dir=/usr/local/bin --filename=composer
# Instala sqlserver drives
# apt-get install curl apt-transport-https
# wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
# echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
# apt-get update
# sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
# locale-gen
# pecl install sqlsrv
# pecl install pdo_sqlsrv
# phpenmod sqlsrv pdo_sqlsrv
# # adiciona sqlserver drives nas extensions do php
# bash -c 'printf "; priority=20\nextension=sqlsrv.so\n" > /etc/php/8.0/mods-available/sqlsrv.ini'
# bash -c 'printf "; priority=30\nextension=pdo_sqlsrv.so\n" > /etc/php/8.0/mods-available/pdo_sqlsrv.ini'
# Instala Swoole
pecl install -D 'enable-sockets="no" enable-openssl="yes" enable-http2="yes" enable-mysqlnd="yes" enable-swoole-json="no" enable-swoole-curl="yes"' swoole

# Adiciona swoolenas extensions do php
# php -i | grep php.ini
echo "extension=swoole">/etc/php/8.0/cli/conf.d/20-swoole.ini
# php -m | grep swoole
# Instala Redis
service redis-server start
# Instala Laravel
cd /var/www/
composer create-project --no-interaction --prefer-dist laravel/laravel laravel
cd laravel 
# Instala octane
composer require laravel/octane -n
php artisan octane:install --server=swoole
# da permissoes
chown -R :www-data /var/www/laravel/storage/
chown -R :www-data /var/www/laravel/bootstrap/cache/
chmod -R 0777 /var/www/laravel/storage/
chmod -R 0777 /var/www/laravel/bootstrap/cache/
chmod -R 0777 /var/www/laravel/artisan
chown -R www-data.www-data /var/www/laravel/storage
chown -R www-data.www-data /var/www/laravel/bootstrap/cache
mkdir -p /var/www/laravel

# Configura nginx
rm /etc/nginx/sites-available/default
rm /etc/nginx/sites-enabled/default
rm -rf /var/www/html
# cp /var/www/laravel /etc/nginx/sites-available/laravel -r
bash -c 'printf "
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}
server {
    listen 80;
    server_name your.domain.com;
    root /var/www/laravel/public;
    index index.php;

    location = /index.php {
        # Ensure that there is no such file named "not_exists"
        # in your "public" directory.
        try_files /not_exists @swoole;
    }
    # any php files must not be accessed
    #location ~* \.php$ {
    #    return 404;
    #}
    location / {
        try_files $uri $uri/ @swoole;
    }

    location @swoole {
        set $suffix "";

        if ($uri = /index.php) {
            set $suffix ?$query_string;
        }

        proxy_http_version 1.1;
        proxy_set_header Host $http_host;
        proxy_set_header Scheme $scheme;
        proxy_set_header SERVER_PORT $server_port;
        proxy_set_header REMOTE_ADDR $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;

        # IF https
        # proxy_set_header HTTPS "on";

        proxy_pass http://127.0.0.1:8000$suffix;
    }
}
" > /etc/nginx/sites-available/laravel.conf'
ln -s /etc/nginx/sites-available/laravel /etc/nginx/sites-enabled/
service nginx restart
# Instalando e criando supervisor para laravel
apt-get install supervisor
# Octane Supervisor
sudo bash -c 'printf "[program:laravel-octane]
process_name=laravel_octane_02d
command=php /var/www/larave/artisan octane:start
autostart=true
autorestart=true
user=root
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/laravel/storage/logs/octane.log" > /etc/supervisor/conf.d/laravel-octane.conf'
# Queue Superficos
bash -c 'printf "[program:laravel-worker]
process_name=laravel_worker_02d
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