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


#  'instala uns programas básicos'
yum -y install lsb-release apt-transport-https ca-certificates wget
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
yum -y install php php-{common,mysql,xml,xmlrpc,curl,gd,imagick,cli,dev,imap,mbstring,opcache,soap,zip,intl,bcmath,ldap,sqlite,fpm,pear,devel}
#  'instala extensions'
yum -y install curl git unzip supervisor gcc glibc-headers gcc-c++ openssl-devel epel-release
#  'COMPOSER'
# curl -sS https://getcomposer.org/installer | php 
sudo mv composer.phar /usr/bin/composer
chmod +x /usr/bin/composer
# Instala Laravel
cd /var/www
git clone http://pxl0hosp0811.dispositivos.bb.com.br/fbb/ajuda-humanitaria.git laravel
cd laravel
git checkout staging
composer install --no-interaction --prefer-dist --optimize-autoloader
cp .env.example .env

# ================ NODEJS ==================
sudo yum install -y centos-release-scl-rh
sudo yum install -y rh-nodejs10
scl enable rh-nodejs10 bash
npm install

#=========== ajusta permimssões ================
chmod -R 775 .

#change the context of the laravel project directories
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/public(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/storage(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/laravel/bootstrap/cache(/.*)?'
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

alias sail='bash vendor/bin/sail'
sail up -d
sail artisan migrate:fresh --seed
exit