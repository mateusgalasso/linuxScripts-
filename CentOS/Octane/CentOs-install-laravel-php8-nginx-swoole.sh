#! /bin/bash
# tem que dar o comandos a seguir antes de rodar o script
# sudo chmod +x install_laravel.sh
# sudo su
###########################################################
# ------------- On CentOS/RHEL 7.x ------------- 
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

#  'Update and Upgrade'
yum -y update && yum -y upgrade
#  'instala uns programas básicos'
yum -y install lsb-release apt-transport-https ca-certificates wget redis-server nginx unzip libcurl4-openssl-dev
#  'adicliona mais lista de pacotes'
# wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
# echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
#  'update novamente'
yum update -y
#  'instala php 8'
yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum -y install https://extras.getpagespeed.com/release-el7-latest.rpm
rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

yum -y install yum-utils
yum-config-manager --disable 'remi-php*'
yum-config-manager --enable remi-php80
yum -y install php php-{common,mysql,xml,xmlrpc,curl,gd,imagick,cli,dev,imap,mbstring,opcache,soap,zip,intl,bcmath,ldap,pear,devel,redis}
#  'instala extensions'
yum -y install curl git unzip supervisor gcc glibc-headers gcc-c++ openssl-devel epel-release
#  'COMPOSER'
curl -sS https://getcomposer.org/installer | php 
sudo mv composer.phar /usr/bin/composer
chmod +x /usr/bin/composer


#===== Instala Swoole ==================================================
pecl install -D 'enable-sockets="no" enable-openssl="no" enable-http2="no" enable-mysqlnd="no" enable-swoole-json="no" enable-swoole-curl="no"' swoole

# Adiciona swoolenas extensions do php
# php -i | grep php.ini
bash -c 'printf "extension=swoole
allow_url_fopen=off
expose_php=off
log_errors=on" > /etc/php.ini'

#======================================================================== 	



# ========================Instala Laravel=============================
cd /var/www/
# composer create-project --no-interaction --prefer-dist laravel/laravel laravel
git clone git@pxl0hosp0811.dispositivos.bb.com.br:fbb/ajuda-humanitaria.git laravel
cd laravel
composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev
cp .env.producao .env

# da permissoes
chown -R nginx:root /var/www/laravel/storage/
chown -R nginx:root /var/www/laravel/bootstrap/cache/
chown -R nginx:nginx /var/www/laravel
chown -R nginx:nginx /var/www/laravel/storage/
chmod -R 755 storage
chmod -R 755 bootstrap/cache
chmod -R 755 .


# Configura nginx
sudo systemctl stop nginx
sudo systemctl enable nginx
rm -rf /var/www/html
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cp nginx.conf /etc/nginx/conf.d/laravel.conf
cp nginx.conf /etc/nginx/nginx.conf

#Install 'policycoreutils-python' 
yum -y install policycoreutils-python

#change the context of the laravel project directories
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/public(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/storage(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/app(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/bootstrap(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/config(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/database(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/resources(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/routes(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/vendor(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/tests(/.*)?'

#run SELinux restorecon command
restorecon -Rv '/var/www/laravel/'

#============= INSTALL REDIS ==============
#1. install redis (make sure EPEL repository is already installed)
yum -y install redis
#2. start redis service
systemctl start redis
#3. start redis on server boot
systemctl enable redis


#===== INSTALL SUPERVISOR ======
yum -y install supervisor

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
stopwaitsecs=3600" > /etc/supervisord.d/laravel-worker.ini'

# Octane
bash -c 'printf "[program:laravel-octane]
process_name=laravel-octane
command=php /var/www/laravel/artisan octane:start
autostart=true
autorestart=true
user=root
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/laravel/storage/logs/octane.log
stopwaitsecs=3600" > /etc/supervisord.d/laravel-octane.ini'

#  HORIZON 
bash -c 'printf "[program:laravel-horizon]
process_name=laravel-horizon
command=php /var/www/laravel/artisan horizon
autostart=true
autorestart=true
user=root
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/laravel/storage/logs/horizon.log
stopwaitsecs=3600" > /etc/supervisord.d/laravel-horizon.ini'

supervisord -c /etc/supervisord.conf

# 4. read the newly edited config file:
supervisorctl reread

# 5. update the config:
supervisorctl update

# 6. start the queue worker:
supervisorctl start laravel-worker:*
supervisorctl start laravel-octane:*
supervisorctl start laravel-horizon:*


#pra ver se esta funcionandoo
#supervisorctl status
#laravel-worker:laravel_worker    RUNNING   pid 105535, uptime 0:00:03

# ======= CRONTAB =================
bash -c 'echo "* * * * * cd /var/www/laravel && php artisan schedule:run >> /dev/null 2>&1" >> /etc/crontab'
systemctl restart crond.service

# Inicia servicos
systemctl start nginx
systemctl enable nginx

# ============== install docker ===================
# https://docs.docker.com/engine/install/centos/
yum install -y yum-utils
yum-config-manager yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo  
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker.service
systemctl enable containerd.service
groupadd docker
usermod -aG docker deployer
newgrp docker
yum install -y docker-compose
# =============== MEILISEARCH =================
cd
docker run -d --rm -p 7700:7700     -v $(pwd)/data.ms:/data.ms     getmeili/meilisearch

# ================ NODEJS ==================
sudo yum install -y centos-release-scl-rh
sudo yum install -y rh-nodejs10
scl enable rh-nodejs10 bash

exit