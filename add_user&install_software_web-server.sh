#!/bin/bash

#================#
# For CentOS 7.0 #
#================#

######## CONFIG ##########
# setting user
declare -r user="www"
declare -r password="$(openssl rand -base64 13)"
declare -r serverRoot="/home/$user/web/public"
# setting webserver
declare -r webserver="nginx"
declare -r php="php82" # php-fpm 8.0
declare -r router="index.php"
declare -r domain="localhost"
declare -r timezone="UTC"
# setting pgsql
declare -r pgsql="15"
declare -r postgresql="postgresql-$pgsql"
declare -r DB_NAME="test_dev"
declare -r DB_USER="dev"
declare -r DB_PWD="$(openssl rand -base64 13)"            #$(openssl rand -base64 15)
# settings mysql
declare -r MYSQL="80"         #version MYSQL SERVER
declare -r usr="dev"
declare -r pass="$(openssl rand -base64 13)"
declare -r dbname="test_dev"

##########################




echo
printf "*****  *****"
echo
read -p "*****  Start Installation Add User Creation *****" -t 5
echo
echo
## Adding user
#
#
/usr/sbin/useradd "$user" -s "/usr/bin/bash" -m -d "/home/$user"
#
#
## Adding password
echo "$user:$password" | /usr/sbin/chpasswd
usermod -a -G wheel $user
mkdir /home/$user/web /home/$user/.ssh
cat << EOF >/home/$user/.ssh/authorized_keys
ssh-rsa AAAAB
EOF
echo "----- Adding sudo user install and others manipulation  without password -----"
cat << EOF >/etc/sudoers.d/sudoer-users
# User Cloud
$user ALL=(ALL)	NOPASSWD: ALL
EOF
echo
chown -R $user:$user /home/$user/web /home/$user/.ssh
chmod -R 700 /home/$user/.ssh
chmod 600 /home/$user/.ssh/authorized_keys
echo
echo
echo
echo -e "User\tLogin\tPassword\tDatabase" >> /root/account_data.csv
echo -e "useradd\t$user\t$password" >> /root/account_data.csv
echo
echo
echo
read -p "*****  $user CTREATE  USER ACCESS *****" -t 5
echo
echo
echo
printf "*****  Add Repos Creation & Install software *****"
echo
rpm -Uvh https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
rpm -Uvh https://repo.mysql.com/mysql$MYSQL-community-release-el7-3.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022

# Installation
yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm -y
yum -y install yum-utils
yum-config-manager --enable remi-php82
yum install nginx php php-fpm php-mysqlnd php-pgsql php-gd php-imagick php-json php-opcache php-mcrypt php-curl php-mbstring php-intl php-dom php-zip php-soap postgresql$pgsql-server wget python3 mysql-community-server snapd unzip fish mc -y
echo
echo "----- $postgresql, $php, $timezone INSTALL ACCESS -----"
echo
echo
printf "*****  Configuration POSTGRESQL server & ADD USER & CREATE DB *****"
echo
Configuration
su - postgres -c /usr/pgsql-$pgsql/bin/initdb
sed -i 4i'host   all             all                                      md5' /var/lib/pgsql/$pgsql/data/pg_hba.conf
sed -i 4i'host   all             all                   ::1/128            md5' /var/lib/pgsql/$pgsql/data/pg_hba.conf
sed -i 4i'host   all             all             127.0.0.1/32            md5' /var/lib/pgsql/$pgsql/data/pg_hba.conf
systemctl enable $postgresql
systemctl start $postgresql
cd /tmp
su - postgres -s /bin/bash -c "psql -c \"CREATE DATABASE $DB_NAME;\""
su - postgres -s /bin/bash -c "psql -c \"CREATE USER $DB_USER WITH password '$DB_PWD';\""
su - postgres -s /bin/bash -c "psql -c \"ALTER USER $DB_USER CREATEDB CREATEROLE ;\""
su - postgres -s /bin/bash -c "psql -c \"GRANT ALL privileges ON DATABASE $DB_NAME TO $DB_USER;\""

#echo -e "pgsql\t$DB_USER\t$DB_PWD\t$DB_NAME" >> /root/account_data.csv
echo
echo "DB NAME: $DB_NAME"
echo "USER NAME DB: $DB_USER"
echo "PASSWORD: $DB_PWD"
echo
echo
echo "----- END DATABASE POSTGRESQL ACCESS -----"
echo
echo

systemctl start mysqld
echo
printf "*****  Configuration MYSQL server & ADD USER & CREATE DB *****"
echo
grep "A temporary password" /var/log/mysqld.log

mysql_secure_installation


mysql -u root -p << MYSQL_SCRIPT
CREATE DATABASE $dbname;
CREATE USER $usr@localhost IDENTIFIED BY '$pass';
GRANT ALL PRIVILEGES ON $dbname.* TO $usr@localhost;
FLUSH PRIVILEGES;
MYSQL_SCRIPT
##GRANT ALL PRIVILEGES ON `$usr\_%`.* TO $usr@localhost;
echo
echo
echo
echo "DB NNAME: $dbname"
echo "USER NAME DB: $usr"
echo "PASSWORD: $pass"
echo -e "mysql\t$usr\t$pass\t$dbname" >> /root/account_data.csv
echo
echo "----- END CTEATE DATABASES ACCESS -----"
echo
chkconfig mysqld on
read -p "*****  Configuration WEB SERVER *****" -t 5
#php-fpm configuration
sed -i "s@;date.timezone =@date.timezone = $timezone@g" /etc/php.ini
sed -i "s@display_errors = Off@display_errors = On@g" /etc/php.ini
sed -i "s@html_errors = On@html_errors = Off@g" /etc/php.ini
sed -i "s@memory_limit = 128M@memory_limit = 512M@g" /etc/php.ini
sed -i "s@max_execution_time = 30@max_execution_time = 300@g" /etc/php.ini
sed -i "s@max_input_time = 60@max_input_time = 300@g" /etc/php.ini
sed -i "s@;catch_workers_output =@catch_workers_output =@g" /etc/php-fpm.d/www.conf
sed -i "s@;php_flag\[display_errors\] = off@php_flag\[display_errors\] = on@" /etc/php-fpm.d/www.conf

# permissions
sed -i "s@user  nginx@user  $webserver@g" /etc/nginx/nginx.conf
sed -i "s@user = apache@user = $webserver@g" /etc/php-fpm.d/www.conf
sed -i "s@group = nginx@group = $webserver@g" /etc/php-fpm.d/www.conf
sed -i "s@group = apache@group = $webserver@g" /etc/php-fpm.d/www.conf
sed -i "s@;listen.group = nobody@listen.group = $webserver@g" /etc/php-fpm.d/www.conf
sed -i "s@;listen.owner = nobody@listen.owner = $webserver@g" /etc/php-fpm.d/www.conf
sed -i "s@listen = 127.0.0.1:9000@listen = /var/run/php-fpm/php-fpm.sock@g" /etc/php-fpm.d/www.conf
sed -i "s@;php_value[opcache.file_cache]  = /var/lib/php/opcache@php_value[opcache.file_cache]  = /var/lib/php/opcache@g" /etc/php-fpm.d/www.conf
sed -i "s@;listen.mode = 0660@listen.mode = 0660@g" /etc/php-fpm.d/www.conf
sed -i "s@SELINUX=enforcing@SELINUX=disabled@g" /etc/sysconfig/selinux
sed -i "s@SELINUX=enforcing@SELINUX=disabled@g" /etc/selinux/config

setenforce 0

mkdir -p $serverRoot
yum install bzip2 traceroute gdisk atop htop iftop -y

cat << EOF > $serverRoot/$router
<!DOCTYPE html>
<html>
<head>
    <meta name='robots' content='noindex,nofollow'>
    <style type='text/css'>
        html, body {
            width: 100vw;
            height: 100vh;
            background-color: white;
        }
        .box {
            width: 100vw;
            height: 100vh;
            background-color: white;
        }
        .box:after {
            content: ' ';
            border-bottom: 100vh solid #F3F7FC;
            border-left: 100vw solid transparent;
            width: 0;
            position: absolute;
        }
        .image {
            z-index: 1;
            border-radius: 15px;
            width: 700px;
            left: 50%;
            margin-left: -400px;
            position: absolute;
            top: 50%;
            transform: translateY(-50%);
        }
        #hostname {
            position: absolute;
            left: 27%;
            top: 35%;
            font-family: 'Roboto';
            font-style: normal;
            font-weight: 400;
            font-size: 24px;
            line-height: 30px;
            color: #FFFFFF;
        }
        h5 {
            left: 14%;
            top: 40%;
            position: absolute;
            font-size: 0.83em;
            margin-block-start: 1.67em;
            margin-block-end: 1.67em;
            margin-inline-start: 80px;
            margin-inline-end: 190px;
            font-weight: bold;
            color: #535353;
            transform: translateY(0%);
        }
    </style>
</head>
<body>
<div class='box'>
    <div class='image'>
        <span><center><h2><p>Server configured successfully!</p></h2></br></center><h5> <p> Server : <?php \$info_OS = shell_exec('cat /etc/system-release'); echo \$info_OS; ?></p><p> Web-Server : <?php \$info_web = getenv('SERVER_SOFTWARE'); echo \$info_web; ?> PHP-FPM : version <?php \$info_php = phpversion(); echo \$info_php; ?> </p><p> DB PostgreSQL : <?php \$info_db = shell_exec('psql --version'); echo \$info_db; ?></p><p> DB MySQL : <?php \$info_db2 = shell_exec('mysql --version'); echo \$info_db2; ?></p><p> Time Server : <?php \$date = date('d.m.Y l H:i:s'); \$time_zone = date_default_timezone_get(); echo \$date;  echo \$time_zone; ?></p><p> Your IP : <a id="yip"></a></p></h5></span>
        <div id='hostname'>...</div>
        <img src='data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPCEtLSBHZW5lcmF0b3I6IEFkb2JlIElsbHVzdHJhdG9yIDI2LjMuMSwgU1ZHIEV4cG9ydCBQbHVnLUluIC4gU1ZHIFZlcnNpb246IDYuMDAgQnVpbGQgMCkgIC0tPgo8c3ZnIHZlcnNpb249IjEuMCIgaWQ9ItCh0LvQvtC5XzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IgoJIHZpZXdCb3g9IjAgMCA4MDAgNjAwIiBzdHlsZT0iZW5hYmxlLWJhY2tncm91bmQ6bmV3IDAgMCA4MDAgNjAwOyIgeG1sOnNwYWNlPSJwcmVzZXJ2ZSI+CjxzdHlsZSB0eXBlPSJ0ZXh0L2NzcyI+Cgkuc3Qwe29wYWNpdHk6MC41O2ZpbGw6I0JGQ0NFMDtlbmFibGUtYmFja2dyb3VuZDpuZXcgICAgO30KCS5zdDF7ZmlsbDojRkZGRkZGO30KCS5zdDJ7ZmlsbDojNTI1RDZEO30KCS5zdDN7ZmlsbDojMjMxRjIwO30KCS5zdDR7ZmlsbDojQkZDQ0UwO30KCS5zdDV7ZmlsbDojRDVERUU5O30KCS5zdDZ7ZmlsbDpub25lO3N0cm9rZTojMjMxRjIwO3N0cm9rZS1taXRlcmxpbWl0OjEwO30KCS5zdDd7ZmlsbDojRjNGN0ZDO30KCS5zdDh7ZmlsbDojRTJFQUY0O30KCS5zdDl7ZmlsbDojMjYyOTM4O30KCS5zdDEwe2ZpbGw6bm9uZTtzdHJva2U6I0JGQ0NFMDtzdHJva2Utd2lkdGg6NDtzdHJva2UtbWl0ZXJsaW1pdDoxMDt9Cgkuc3QxMXtmaWxsOiNGRkVEMDA7fQo8L3N0eWxlPgo8cGF0aCBjbGFzcz0ic3QwIiBkPSJNNzIxLjIsMTE5LjVoLTQyLjRsMjAuNSwyMC41bC0xOS41LDE5LjVoLTAuM3YwLjdsMTkuOCwxOS44bC0xOS41LDE5LjVoLTAuM3YwLjdsMTkuOCwxOS44bC0xOS41LDE5LjVoLTAuMwoJdjAuN2wxOS44LDE5LjhsLTE5LjUsMTkuNWgtMWwyMC41LDIwLjVsLTE5LjUsMTkuNWgtMC4zdjAuN2wxOS44LDE5LjhsLTE5LjUsMTkuNWgtMC4zdjAuN2wxOS44LDE5LjhsLTE5LjUsMTkuNWgtMC4zdjAuNwoJbDE5LjgsMTkuOGwtMTkuNSwxOS41aC0wLjN2MC43bDE5LjgsMTkuOGwtMTkuNSwxOS41aC0wLjN2MC43bDE5LjgsMTkuOGwtMTkuNiwxOS42bDAuNywwLjdsMTkuNi0xOS42bDE5LjYsMTkuNmwwLjctMC43TDcwMC43LDUwMAoJbDE5LjgtMTkuOHYtMC43aC0wLjNMNzAwLjcsNDYwbDE5LjgtMTkuOHYtMC43aC0wLjNMNzAwLjcsNDIwbDIwLjUtMjAuNWgtMUw3MDAuNywzODBsMTkuOC0xOS44di0wLjdoLTAuM0w3MDAuNywzNDBsMTkuOC0xOS44Cgl2LTAuN2gtMC4zTDcwMC43LDMwMGwxOS44LTE5Ljh2LTAuN2gtMC4zTDcwMC43LDI2MGwxOS44LTE5Ljh2LTAuN2gtMC4zTDcwMC43LDIyMGwxOS44LTE5Ljh2LTAuN2gtMC4zTDcwMC43LDE4MGwxOS44LTE5Ljh2LTAuNwoJaC0wLjNMNzAwLjcsMTQwTDcyMS4yLDExOS41eiBNNjgxLjIsMTIwLjVoMzcuNkw3MDAsMTM5LjNMNjgxLjIsMTIwLjV6IE03MDAsNDk5LjNsLTE4LjgtMTguOGgzNy42TDcwMCw0OTkuM3ogTTcxOC44LDQ3OS41aC0zNy42CglsMTguOC0xOC44TDcxOC44LDQ3OS41eiBNNzAwLDQ1OS4zbC0xOC44LTE4LjhoMzcuNkw3MDAsNDU5LjN6IE03MTguOCw0MzkuNWgtMzcuNmwxOC44LTE4LjhMNzE4LjgsNDM5LjV6IE03MDAsNDE5LjNsLTE4LjgtMTguOAoJaDM3LjZMNzAwLDQxOS4zeiBNNzE4LjgsMzk5LjVoLTM3LjZsMTguOC0xOC44TDcxOC44LDM5OS41eiBNNzAwLDM3OS4zbC0xOC44LTE4LjhoMzcuNkw3MDAsMzc5LjN6IE03MTguOCwzNTkuNWgtMzcuNmwxOC44LTE4LjgKCUw3MTguOCwzNTkuNXogTTcwMCwzMzkuM2wtMTguOC0xOC44aDM3LjZMNzAwLDMzOS4zeiBNNzE4LjgsMzE5LjVoLTM3LjZsMTguOC0xOC44TDcxOC44LDMxOS41eiBNNzAwLDI5OS4zbC0xOC44LTE4LjhoMzcuNgoJTDcwMCwyOTkuM3ogTTcxOC44LDI3OS41aC0zNy42bDE4LjgtMTguOEw3MTguOCwyNzkuNXogTTcwMCwyNTkuM2wtMTguOC0xOC44aDM3LjZMNzAwLDI1OS4zeiBNNzE4LjgsMjM5LjVoLTM3LjZsMTguOC0xOC44CglMNzE4LjgsMjM5LjV6IE03MDAsMjE5LjNsLTE4LjgtMTguOGgzNy42TDcwMCwyMTkuM3ogTTcxOC44LDE5OS41aC0zNy42bDE4LjgtMTguOEw3MTguOCwxOTkuNXogTTcwMCwxNzkuM2wtMTguOC0xOC44aDM3LjYKCUw3MDAsMTc5LjN6IE03MTguOCwxNTkuNWgtMzcuNmwxOC44LTE4LjhMNzE4LjgsMTU5LjV6Ii8+CjxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik03OTkuNiw4MC40bDAuMi0xLjJMNzgwLjcsNjBsMTktMTlsLTAuMS0xLjNMNzgwLDU5LjNsLTE5LjUtMTkuNXYtMC4zaC0wLjdMNzQwLDU5LjNsLTE5LjUtMTkuNXYtMWwtMC41LDAuNQoJTDcwMC43LDIwbDE5LjYtMTkuNkw3MjAsMGgtMC43TDcwMCwxOS4zTDY4MC43LDBINjgwbC0wLjQsMC40TDY5OS4zLDIwbC0xOS42LDE5LjZMNjYwLDU5LjNsLTE5LjUtMTkuNXYtMC4zaC0wLjdMNjIwLDU5LjMKCWwtMTkuNS0xOS41di0wLjNoLTAuN0w1ODAsNTkuM2wtMjAtMjBsLTAuNSwwLjN2NDAuOWgwLjdMNTgwLDYwLjdsMTkuOCwxOS44aDAuN3YtMC4zTDYyMCw2MC43bDE5LjgsMTkuOGgwLjd2LTAuM0w2NjAsNjAuNwoJbDE5LjUsMTkuNXYxTDcwMCw2MC43bDIwLjUsMjAuNXYtMUw3NDAsNjAuN2wxOS44LDE5LjhoMC43di0wLjNMNzgwLDYwLjdMNzk5LjYsODAuNHogTTU2MC41LDc4LjhWNDEuMkw1NzkuMyw2MEw1NjAuNSw3OC44egoJIE01OTkuNSw3OC44TDU4MC43LDYwbDE4LjgtMTguOFY3OC44eiBNNjAwLjUsNzguOFY0MS4yTDYxOS4zLDYwTDYwMC41LDc4Ljh6IE02MzkuNSw3OC44TDYyMC43LDYwbDE4LjgtMTguOFY3OC44eiBNNjQwLjUsNzguOAoJVjQxLjJMNjU5LjMsNjBMNjQwLjUsNzguOHogTTY2MC43LDYwbDE4LjgtMTguOHYzNy42TDY2MC43LDYweiBNNjgwLjUsNzguOFY0MS4yTDY5OS4zLDYwTDY4MC41LDc4Ljh6IE02ODAuOCw0MC4xbC0wLjIsMEw3MDAsMjAuNwoJTDcxOS4zLDQwTDcwMCw1OS4zTDY4MC44LDQwLjF6IE03MTkuNSw3OC44TDcwMC43LDYwbDE4LjgtMTguOFY3OC44eiBNNzIwLjUsNzguOFY0MS4yTDczOS4zLDYwTDcyMC41LDc4Ljh6IE03NTkuNSw3OC44TDc0MC43LDYwCglsMTguOC0xOC44Vjc4Ljh6IE03NjAuNSw3OC44VjQxLjJMNzc5LjMsNjBMNzYwLjUsNzguOHoiLz4KPHBhdGggY2xhc3M9InN0MSIgZD0iTTE4NCw0NDUuNmMtMTIuNywwLTIzLTkuNC0yMy0yMC45VjE0MS45YzAtMTEuNSwxMC4zLTIwLjksMjMtMjAuOWg0MzJjMTIuNywwLDIzLDkuNCwyMywyMC45djI4Mi45CgljMCwxMS41LTEwLjMsMjAuOS0yMywyMC45SDE4NHoiLz4KPHBhdGggY2xhc3M9InN0MiIgZD0iTTYxNiwxMjEuOGMxMi4xLDAsMjIsOC45LDIyLDE5Ljl2MjgyLjJjMCwxMS05LjksMTkuOS0yMiwxOS45SDE4NGMtMTIuMSwwLTIyLTguOS0yMi0xOS45VjE0MS43CgljMC0xMSw5LjktMTkuOSwyMi0xOS45SDYxNnogTTYxNiwxMjBIMTg0Yy0xMy4zLDAtMjQsOS43LTI0LDIxLjd2MjgyLjJjMCwxMiwxMC43LDIxLjcsMjQsMjEuN2g0MzJjMTMuMywwLDI0LTkuNywyNC0yMS43VjE0MS43CglDNjQwLDEyOS43LDYyOS4zLDEyMCw2MTYsMTIweiIvPgo8cGF0aCBjbGFzcz0ic3QzIiBkPSJNNjE0LDE5MUgxODZjLTguOCwwLTE2LTcuMi0xNi0xNnYtMjhjMC04LjgsNy4yLTE2LDE2LTE2aDQyOGM4LjgsMCwxNiw3LjIsMTYsMTZ2MjgKCUM2MzAsMTgzLjgsNjIyLjgsMTkxLDYxNCwxOTF6Ii8+CjxwYXRoIGNsYXNzPSJzdDQiIGQ9Ik03MjAuNSw1MjAuNWgtNDF2LTQ0MWg0MVY1MjAuNXogTTY4MC41LDUxOS41aDM5di00MzloLTM5VjUxOS41eiIvPgo8cGF0aCBjbGFzcz0ic3Q1IiBkPSJNNzU2LDU5OUg2NDRjLTguOCwwLTE2LTcuMi0xNi0xNnYtMjJjMC04LjgsNy4yLTE2LDE2LTE2aDExMmM4LjgsMCwxNiw3LjIsMTYsMTZ2MjIKCUM3NzIsNTkxLjgsNzY0LjgsNTk5LDc1Niw1OTl6Ii8+CjxwYXRoIGNsYXNzPSJzdDUiIGQ9Ik03NTUsNTA2LjVoLTI4djEyaDI4VjUwNi41eiIvPgo8cGF0aCBjbGFzcz0ic3Q1IiBkPSJNNzU1LDQ5My41aC0yOHYxMmgyOFY0OTMuNXoiLz4KPHBhdGggY2xhc3M9InN0NSIgZD0iTTc1NSw0ODAuNWgtMjh2MTJoMjhWNDgwLjV6Ii8+CjxwYXRoIGNsYXNzPSJzdDUiIGQ9Ik03NTUsNDY3LjVoLTI4djEyaDI4VjQ2Ny41eiIvPgo8cGF0aCBjbGFzcz0ic3Q0IiBkPSJNNzIwLjUsNDFoLTQxVjBoNDFWNDF6IE02ODAuNSw0MGgzOVYxaC0zOVY0MHoiLz4KPHBhdGggY2xhc3M9InN0MyIgZD0iTTQwNCw4NmgtMTJjLTIuMiwwLTQtMS44LTQtNHYtMmgyMHYyQzQwOCw4NC4yLDQwNi4yLDg2LDQwNCw4NnoiLz4KPHBhdGggY2xhc3M9InN0MSIgZD0iTTYzOS4zLDU5MGg3LjdsNS42LTEyaC03LjdMNjM5LjMsNTkweiIvPgo8cGF0aCBjbGFzcz0ic3QxIiBkPSJNNjUzLDU5MGg3LjdsNS42LTEyaC03LjdMNjUzLDU5MHoiLz4KPHBhdGggY2xhc3M9InN0MSIgZD0iTTY2Ni44LDU5MGg3LjdsNS42LTEyaC03LjdMNjY2LjgsNTkweiIvPgo8cGF0aCBjbGFzcz0ic3QxIiBkPSJNNjgwLjYsNTkwaDcuN2w1LjYtMTJoLTcuN0w2ODAuNiw1OTB6Ii8+CjxwYXRoIGNsYXNzPSJzdDEiIGQ9Ik02OTQuMyw1OTBoNy43bDUuNi0xMmgtNy43TDY5NC4zLDU5MHoiLz4KPHBhdGggY2xhc3M9InN0MSIgZD0iTTcwOC4xLDU5MGg3LjdsNS42LTEyaC03LjdMNzA4LjEsNTkweiIvPgo8cGF0aCBjbGFzcz0ic3QxIiBkPSJNNzIxLjgsNTkwaDcuN2w1LjYtMTJoLTcuN0w3MjEuOCw1OTB6Ii8+CjxwYXRoIGNsYXNzPSJzdDEiIGQ9Ik03MzUuNiw1OTBoNy43bDUuNi0xMmgtNy43TDczNS42LDU5MHoiLz4KPHBhdGggY2xhc3M9InN0MSIgZD0iTTc0OS40LDU5MGg3LjdsNS42LTEySDc1NUw3NDkuNCw1OTB6Ii8+CjxwYXRoIGNsYXNzPSJzdDEiIGQ9Ik0zNDUuMiwzNDZjNS44LDAsMTAuNS00LjcsMTAuNS0xMC41YzAtNS44LTQuNy0xMC41LTEwLjUtMTAuNWMtNS44LDAtMTAuNSw0LjctMTAuNSwxMC41CglDMzM0LjcsMzQxLjQsMzM5LjQsMzQ2LDM0NS4yLDM0NnoiLz4KPHBhdGggY2xhc3M9InN0NiIgZD0iTTM5Ny45LDgwdjM4LjljMy41LDAsNi4zLDAuNSw2LjMsMWMwLDAuNi0yLjgsMS02LjMsMXMtNi4zLTAuNS02LjMtMSIvPgo8cGF0aCBjbGFzcz0ic3Q1IiBkPSJNNzMxLDEyMC41aC01MWMtNy43LDAtMTQtNi4zLTE0LTE0di0xM2MwLTcuNyw2LjMtMTQsMTQtMTRoNTFWMTIwLjV6Ii8+CjxwYXRoIGNsYXNzPSJzdDciIGQ9Ik03MjQsMTA3aC0xMnY4aDEyVjEwN3oiLz4KPHBhdGggY2xhc3M9InN0NSIgZD0iTTkwLDYwMEgyMS4yTDQuNiw0OThoMTAyTDkwLDYwMHoiLz4KPHBhdGggY2xhc3M9InN0OCIgZD0iTTEwNS4yLDUxMy4xSDZjLTMuMywwLTYtMi43LTYtNnYtMTIuNGMwLTMuMywyLjctNiw2LTZoOTkuMmMzLjMsMCw2LDIuNyw2LDZ2MTIuNAoJQzExMS4yLDUxMC40LDEwOC41LDUxMy4xLDEwNS4yLDUxMy4xeiIvPgo8cGF0aCBjbGFzcz0ic3QzIiBkPSJNNTYuMSw0MDIuNmMwLTE4LjctMTUuMy0zMy0zNC0zM0g4LjRjMCwxOC4yLDE0LjgsMzMsMzMsMzNINTYuMXoiLz4KPHBhdGggY2xhc3M9InN0MyIgZD0iTTU2LjEsNDAyLjZoLTF2ODYuMWgxVjQwMi42eiIvPgo8cGF0aCBjbGFzcz0ic3QzIiBkPSJNODAwLDU5OUgwdjFoODAwVjU5OXoiLz4KPHBhdGggY2xhc3M9InN0NSIgZD0iTTc2Myw1NDUuNUg2MzdjLTUuMiwwLTkuNS00LjMtOS41LTkuNXYtN2MwLTUuMiw0LjMtOS41LDkuNS05LjVoMTI2YzUuMiwwLDkuNSw0LjMsOS41LDkuNXY3CglDNzcyLjUsNTQxLjIsNzY4LjIsNTQ1LjUsNzYzLDU0NS41eiBNNjM3LDUyMC41Yy00LjcsMC04LjUsMy44LTguNSw4LjV2N2MwLDQuNywzLjgsOC41LDguNSw4LjVoMTI2YzQuNywwLDguNS0zLjgsOC41LTguNXYtNwoJYzAtNC43LTMuOC04LjUtOC41LTguNUg2Mzd6Ii8+CjxwYXRoIGNsYXNzPSJzdDMiIGQ9Ik01MTcuNSwzOTAuMXYzOC43aC00M3YtMzguN2gtMXYyMDkuNGgxdi0yMy4zaDQzdjIzLjNoMVYzOTAuMUg1MTcuNXogTTUxNy41LDQyOS45djIzLjNoLTQzdi0yMy4zSDUxNy41egoJIE00NzQuNSw1MjYuNHYtMjMuM2g0M3YyMy4zSDQ3NC41eiBNNTE3LjUsNTI3LjV2MjMuM2gtNDN2LTIzLjNINTE3LjV6IE00NzQuNSw1MDJ2LTIzLjNoNDNWNTAySDQ3NC41eiBNNDc0LjUsNDc3LjZ2LTIzLjNoNDN2MjMuMwoJSDQ3NC41eiBNNDc0LjUsNTc1LjF2LTIzLjNoNDN2MjMuM0g0NzQuNXoiLz4KPHBhdGggY2xhc3M9InN0NiIgZD0iTTMxNC45LDEzMS45bDg1LTEzbDg1LDEzIi8+CjxwYXRoIGNsYXNzPSJzdDMiIGQ9Ik00MDIuOSwxMTguOWgtOGMtMC41LDAtMS0wLjUtMS0xVjk5LjFjMC0wLjUsMC41LTEsMS0xaDhjMC41LDAsMSwwLjUsMSwxdjE4LjgKCUM0MDMuOSwxMTguNSw0MDMuNSwxMTguOSw0MDIuOSwxMTguOXoiLz4KPHBhdGggY2xhc3M9InN0OCIgZD0iTTI2LjYsMTA5djIyYzAsOS45LDguMSwxOCwxOCwxOGgyMmM5LjksMCwxOC04LjEsMTgtMTh2LTIyYzAtMi45LTAuNy01LjYtMS45LThIMjguNQoJQzI3LjMsMTAzLjQsMjYuNiwxMDYuMSwyNi42LDEwOXoiLz4KPHBhdGggY2xhc3M9InN0NSIgZD0iTTY2LjYsOTFoLTIyYy03LDAtMTMuMSw0LjEtMTYuMSwxMGg1NC4yQzc5LjcsOTUuMSw3My42LDkxLDY2LjYsOTF6Ii8+CjxwYXRoIGNsYXNzPSJzdDkiIGQ9Ik01My42LDEzNmMtMC4xLDAtMC4yLDAtMC40LDBjLTEuMS0wLjItMS44LTEuMy0xLjYtMi4zbDQtMjFjMC4yLTEuMSwxLjMtMS44LDIuMy0xLjZjMS4xLDAuMiwxLjgsMS4zLDEuNiwyLjMKCWwtNCwyMUM1NS40LDEzNS4zLDU0LjYsMTM2LDUzLjYsMTM2eiIvPgo8cGF0aCBjbGFzcz0ic3Q5IiBkPSJNNDQuNiwxMzJjLTAuNiwwLTEuMS0wLjItMS41LTAuN2wtNi03Yy0wLjctMC44LTAuNi0yLjEsMC4yLTIuOGMwLjgtMC43LDIuMS0wLjYsMi44LDAuMmw2LDcKCWMwLjcsMC44LDAuNiwyLjEtMC4yLDIuOEM0NS41LDEzMS44LDQ1LjEsMTMyLDQ0LjYsMTMyeiIvPgo8cGF0aCBjbGFzcz0ic3Q5IiBkPSJNMzguNiwxMjVjLTAuNSwwLTAuOS0wLjItMS4zLTAuNWMtMC44LTAuNy0wLjktMi0wLjItMi44bDYtN2MwLjctMC44LDItMC45LDIuOC0wLjJjMC44LDAuNywwLjksMiwwLjIsMi44CglsLTYsN0MzOS43LDEyNC44LDM5LjIsMTI1LDM4LjYsMTI1eiIvPgo8cGF0aCBjbGFzcz0ic3Q5IiBkPSJNNjYuNiwxMzJjLTAuNSwwLTAuOS0wLjItMS4zLTAuNWMtMC44LTAuNy0wLjktMi0wLjItMi44bDYtN2MwLjctMC44LDItMC45LDIuOC0wLjJjMC44LDAuNywwLjksMiwwLjIsMi44CglsLTYsN0M2Ny43LDEzMS44LDY3LjIsMTMyLDY2LjYsMTMyeiIvPgo8cGF0aCBjbGFzcz0ic3Q5IiBkPSJNNzIuNiwxMjVjLTAuNiwwLTEuMS0wLjItMS41LTAuN2wtNi03Yy0wLjctMC44LTAuNi0yLjEsMC4yLTIuOGMwLjgtMC43LDIuMS0wLjYsMi44LDAuMmw2LDcKCWMwLjcsMC44LDAuNiwyLjEtMC4yLDIuOEM3My41LDEyNC44LDczLjEsMTI1LDcyLjYsMTI1eiIvPgo8cGF0aCBjbGFzcz0ic3Q5IiBkPSJNMzE4LjgsNDkuNWM1LjUsMCwxMC00LjUsMTAtMTBjMC01LjUtNC41LTEwLTEwLTEwYy01LjUsMC0xMCw0LjUtMTAsMTBDMzA4LjgsNDUsMzEzLjMsNDkuNSwzMTguOCw0OS41eiIvPgo8cGF0aCBjbGFzcz0ic3Q0IiBkPSJNMzQ3LjgsNDFWMzhsLTQuNS0wLjdjLTAuMi0xLjgtMC41LTMuNS0xLTUuMmwzLjgtMi40bC0xLjEtMi43bC00LjQsMWMtMC44LTEuNi0xLjgtMy0yLjktNC40bDIuNi0zLjcKCWwtMi4xLTIuMWwtMy43LDIuNmMtMS4zLTEuMS0yLjgtMi4xLTQuNC0yLjlsMS00LjRsLTIuNy0xLjFsLTIuNCwzLjhjLTEuNy0wLjUtMy40LTAuOS01LjItMWwtMC43LTQuNWgtMi45bC0wLjcsNC41CgljLTEuOCwwLjItMy41LDAuNS01LjIsMWwtMi40LTMuOGwtMi43LDEuMWwxLDQuNGMtMS42LDAuOC0zLDEuOC00LjQsMi45bC0zLjctMi42bC0yLjEsMi4xbDIuNiwzLjdjLTEuMSwxLjMtMi4xLDIuOC0yLjksNC40CglsLTQuNC0xbC0xLjEsMi43bDMuOCwyLjRjLTAuNSwxLjctMC45LDMuNC0xLDUuMmwtNC41LDAuN1Y0MWw0LjUsMC43YzAuMiwxLjgsMC41LDMuNSwxLDUuMmwtMy44LDIuNGwxLjEsMi43bDQuNC0xCgljMC44LDEuNiwxLjgsMywyLjksNC40bC0yLjYsMy43bDIuMSwyLjFsMy43LTIuNmMxLjMsMS4xLDIuOCwyLjEsNC40LDIuOWwtMSw0LjRsMi43LDEuMWwyLjQtMy44YzEuNywwLjUsMy40LDAuOSw1LjIsMWwwLjcsNC41CgloMi45TDMyMSw2NGMxLjgtMC4yLDMuNS0wLjUsNS4yLTFsMi40LDMuOGwyLjctMS4xbC0xLTQuNGMxLjYtMC44LDMtMS44LDQuNC0yLjlsMy43LDIuNmwyLjEtMi4xbC0yLjYtMy43YzEuMS0xLjMsMi4xLTIuOCwyLjktNC40CglsNC40LDFsMS4xLTIuN2wtMy44LTIuNGMwLjUtMS43LDAuOS0zLjQsMS01LjJMMzQ3LjgsNDF6IE0zMTguOCw1Ny41Yy05LjksMC0xOC04LjEtMTgtMThzOC4xLTE4LDE4LTE4czE4LDguMSwxOCwxOAoJUzMyOC44LDU3LjUsMzE4LjgsNTcuNXoiLz4KPHBhdGggY2xhc3M9InN0MTAiIGQ9Ik0zMTguOCwyMS41djE4Ii8+CjxwYXRoIGNsYXNzPSJzdDEwIiBkPSJNMzAzLjIsNDguNWwxNS42LTkiLz4KPHBhdGggY2xhc3M9InN0MTAiIGQ9Ik0zMzQuNCw0OC41bC0xNS42LTkiLz4KPHBhdGggY2xhc3M9InN0NCIgZD0iTTgwMCw4MC41SDM0NS4xbDEwNC40LTQxSDgwMFY4MC41eiBNMzUwLjUsNzkuNWg0NDh2LTM5SDQ0OS45TDM1MC41LDc5LjV6Ii8+CjxwYXRoIGNsYXNzPSJzdDEiIGQ9Ik03NjMuMSw1OTBoNy4yYzEtMi4xLDEuNi00LjUsMS42LTd2LTVoLTMuM0w3NjMuMSw1OTB6Ii8+CjxwYXRoIGNsYXNzPSJzdDEiIGQ9Ik02MjguMSw1ODQuMWMwLjEsMi4xLDAuNyw0LjEsMS42LDUuOWgzLjRsNS42LTEyaC03LjdMNjI4LjEsNTg0LjF6Ii8+CjxwYXRoIGNsYXNzPSJzdDMiIGQ9Ik02MS4xLDM3Ni42aC0xdjExMi4xaDFWMzc2LjZ6Ii8+CjxwYXRoIGNsYXNzPSJzdDMiIGQ9Ik02MC4xLDM3Ni42YzAtOC41LDYuOS0xNC45LDE1LjQtMTQuOWg2LjJsMCwwYzAsOC4yLTYuNywxNC45LTE0LjksMTQuOUg2MC4xeiIvPgo8cGF0aCBjbGFzcz0ic3Q1IiBkPSJNMjk3LjcsNTY1aC0xNi42bC0xLjQsNUgyOTlMMjk3LjcsNTY1eiIvPgo8cGF0aCBjbGFzcz0ic3Q1IiBkPSJNMjkzLjgsNTUxYy0wLjUtMS43LTIuMS0yLjktMy45LTIuOWgtMS4yYy0xLjgsMC0zLjQsMS4yLTMuOSwyLjlsLTEuNiw2aDEyLjJMMjkzLjgsNTUxeiIvPgo8cGF0aCBjbGFzcz0ic3Q1IiBkPSJNMzAxLjIsNTc4aC0yMy43bC0xLjQsNWgyNi41TDMwMS4yLDU3OHoiLz4KPHBhdGggY2xhc3M9InN0NSIgZD0iTTMwNi4yLDU5NmwtMS40LTVoLTMwLjlsLTEuNCw1aC03LjJ2M2g2LjRIMzA3aDYuNHYtM0gzMDYuMnoiLz4KPHBhdGggY2xhc3M9InN0NSIgZD0iTTU3Ny43LDU2NWgtMTYuNmwtMS40LDVINTc5TDU3Ny43LDU2NXoiLz4KPHBhdGggY2xhc3M9InN0NSIgZD0iTTU3My44LDU1MWMtMC41LTEuNy0yLjEtMi45LTMuOS0yLjloLTEuMmMtMS44LDAtMy40LDEuMi0zLjksMi45bC0xLjYsNmgxMi4yTDU3My44LDU1MXoiLz4KPHBhdGggY2xhc3M9InN0NSIgZD0iTTU4MS4yLDU3OGgtMjMuN2wtMS40LDVoMjYuNUw1ODEuMiw1Nzh6Ii8+CjxwYXRoIGNsYXNzPSJzdDUiIGQ9Ik01ODYuMiw1OTZsLTEuNC01aC0zMC45bC0xLjQsNWgtNy4ydjNoNi40SDU4N2g2LjR2LTNINTg2LjJ6Ii8+CjxwYXRoIGNsYXNzPSJzdDgiIGQ9Ik00MzcuNyw1NjVoLTE2LjZsLTEuNCw1SDQzOUw0MzcuNyw1NjV6Ii8+CjxwYXRoIGNsYXNzPSJzdDgiIGQ9Ik00MzMuOCw1NTFjLTAuNS0xLjctMi4xLTIuOS0zLjktMi45aC0xLjJjLTEuOCwwLTMuNCwxLjItMy45LDIuOWwtMS42LDZoMTIuMkw0MzMuOCw1NTF6Ii8+CjxwYXRoIGNsYXNzPSJzdDgiIGQ9Ik00NDEuMiw1NzhoLTIzLjdsLTEuNCw1aDI2LjVMNDQxLjIsNTc4eiIvPgo8cGF0aCBjbGFzcz0ic3Q4IiBkPSJNNDQ2LjIsNTk2bC0xLjQtNWgtMzAuOWwtMS40LDVoLTcuMnYzaDYuNEg0NDdoNi40di0zSDQ0Ni4yeiIvPgo8cGF0aCBjbGFzcz0ic3Q1IiBkPSJNODMuNiwyMzIuNWgtMzZ2MWgzNlYyMzIuNXoiLz4KPHBhdGggY2xhc3M9InN0NSIgZD0iTTkzLjYsMjQyLjVoLTM2djFoMzZWMjQyLjV6Ii8+CjxwYXRoIGNsYXNzPSJzdDUiIGQ9Ik0yMjQsMjVoLTM2djFoMzZWMjV6Ii8+CjxwYXRoIGNsYXNzPSJzdDUiIGQ9Ik0yMzQsMzVoLTM2djFoMzZWMzV6Ii8+CjxnPgoJPGc+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0xOTUuMSwxOTFoOGw1LjgtNy44aC04TDE5NS4xLDE5MXoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTIwOS4yLDE5MWg4bDUuOC03LjhoLThMMjA5LjIsMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNMjIzLjMsMTkxaDhsNS44LTcuOGgtOEwyMjMuMywxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0yMzcuNSwxOTFoOGw1LjgtNy44aC04TDIzNy41LDE5MXoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTI1MS42LDE5MWg4bDUuOC03LjhoLThMMjUxLjYsMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNMjY1LjgsMTkxaDhsNS44LTcuOGgtOEwyNjUuOCwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0yNzkuOSwxOTFoOGw1LjgtNy44aC04TDI3OS45LDE5MXoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTI5NC4xLDE5MWg4bDUuOC03LjhoLThMMjk0LjEsMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNMzA4LjIsMTkxaDhsNS44LTcuOGgtOEwzMDguMiwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0zMjIuNCwxOTFoNy40YzEuMS0xLjQsMS43LTIuOSwxLjctNC41di0zLjJoLTMuNEwzMjIuNCwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0xODMuNSwxODcuMmMwLjEsMS40LDAuNywyLjcsMS42LDMuOGgzLjVsNS44LTcuOGgtOEwxODMuNSwxODcuMnoiLz4KCTwvZz4KCTxnPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNMzM2LjQsMTkxaDhsNS44LTcuOGgtOEwzMzYuNCwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0zNTAuNiwxOTFoOGw1LjgtNy44aC04TDM1MC42LDE5MXoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTM2NC43LDE5MWg4bDUuOC03LjhoLThMMzY0LjcsMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNMzc4LjksMTkxaDhsNS44LTcuOGgtOEwzNzguOSwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0zOTMsMTkxaDhsNS44LTcuOGgtOEwzOTMsMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNDA3LjEsMTkxaDhsNS44LTcuOGgtOEw0MDcuMSwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik00MjEuMywxOTFoOGw1LjgtNy44aC04TDQyMS4zLDE5MXoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTQzNS40LDE5MWg4bDUuOC03LjhoLThMNDM1LjQsMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNDQ5LjYsMTkxaDhsNS44LTcuOGgtOEw0NDkuNiwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik00NjMuNywxOTFoNy40YzEuMS0xLjQsMS43LTIuOSwxLjctNC41di0zLjJoLTMuNEw0NjMuNywxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0zMjQuOSwxODcuMmMwLjEsMS40LDAuNywyLjcsMS42LDMuOGgzLjVsNS44LTcuOGgtOEwzMjQuOSwxODcuMnoiLz4KCTwvZz4KCTxnPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNDc3LjgsMTkxaDhsNS44LTcuOGgtOEw0NzcuOCwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik00OTEuOSwxOTFoOGw1LjgtNy44aC04TDQ5MS45LDE5MXoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTUwNi4xLDE5MWg4bDUuOC03LjhoLThMNTA2LjEsMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNTIwLjIsMTkxaDhsNS44LTcuOGgtOEw1MjAuMiwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik01MzQuMywxOTFoOGw1LjgtNy44aC04TDUzNC4zLDE5MXoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTU0OC41LDE5MWg4bDUuOC03LjhoLThMNTQ4LjUsMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNTYyLjYsMTkxaDhsNS44LTcuOGgtOEw1NjIuNiwxOTF6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik01NzYuOCwxOTFoOGw1LjgtNy44aC04TDU3Ni44LDE5MXoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTU5MC45LDE5MWg4bDUuOC03LjhoLThMNTkwLjksMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNjA1LjEsMTkxaDcuNGMxLjEtMS40LDEuNy0yLjksMS43LTQuNXYtMy4yaC0zLjRMNjA1LjEsMTkxeiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNDY2LjIsMTg3LjJjMC4xLDEuNCwwLjcsMi43LDEuNiwzLjhoMy41bDUuOC03LjhoLThMNDY2LjIsMTg3LjJ6Ii8+Cgk8L2c+CjwvZz4KPGc+Cgk8Zz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTE5Ni4yLDEzOC44aDhsNS44LTcuOGgtOEwxOTYuMiwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTIxMC4zLDEzOC44aDhsNS44LTcuOGgtOEwyMTAuMywxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTIyNC41LDEzOC44aDhsNS44LTcuOGgtOEwyMjQuNSwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTIzOC42LDEzOC44aDhsNS44LTcuOGgtOEwyMzguNiwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTI1Mi44LDEzOC44aDhsNS44LTcuOGgtOEwyNTIuOCwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTI2Ni45LDEzOC44aDhsNS44LTcuOGgtOEwyNjYuOSwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTI4MS4xLDEzOC44aDhsNS44LTcuOGgtOEwyODEuMSwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTI5NS4yLDEzOC44aDhsNS44LTcuOGgtOEwyOTUuMiwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTMwOS40LDEzOC44aDhsNS44LTcuOGgtOEwzMDkuNCwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTMyMy41LDEzOC44aDcuNGMxLjEtMS40LDEuNy0yLjksMS43LTQuNVYxMzFoLTMuNEwzMjMuNSwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTE4NC43LDEzNC45YzAuMSwxLjQsMC43LDIuNywxLjYsMy44aDMuNWw1LjgtNy44aC04TDE4NC43LDEzNC45eiIvPgoJPC9nPgoJPGc+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0zMzcuNSwxMzguOGg4bDUuOC03LjhoLThMMzM3LjUsMTM4Ljh6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0zNTEuNywxMzguOGg4bDUuOC03LjhoLThMMzUxLjcsMTM4Ljh6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0zNjUuOCwxMzguOGg4bDUuOC03LjhoLThMMzY1LjgsMTM4Ljh6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik0zODAsMTM4LjhoOGw1LjgtNy44aC04TDM4MCwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTM5NC4xLDEzOC44aDhsNS44LTcuOGgtOEwzOTQuMSwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTQwOC4zLDEzOC44aDhsNS44LTcuOGgtOEw0MDguMywxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTQyMi40LDEzOC44aDhsNS44LTcuOGgtOEw0MjIuNCwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTQzNi42LDEzOC44aDhsNS44LTcuOGgtOEw0MzYuNiwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTQ1MC43LDEzOC44aDhsNS44LTcuOGgtOEw0NTAuNywxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTQ2NC45LDEzOC44aDcuNGMxLjEtMS40LDEuNy0yLjksMS43LTQuNVYxMzFoLTMuNEw0NjQuOSwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTMyNiwxMzQuOWMwLjEsMS40LDAuNywyLjcsMS42LDMuOGgzLjVsNS44LTcuOGgtOEwzMjYsMTM0Ljl6Ii8+Cgk8L2c+Cgk8Zz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTQ3OC45LDEzOC44aDhsNS44LTcuOGgtOEw0NzguOSwxMzguOHoiLz4KCQk8cGF0aCBjbGFzcz0ic3QxMSIgZD0iTTQ5MywxMzguOGg4bDUuOC03LjhoLThMNDkzLDEzOC44eiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNTA3LjIsMTM4LjhoOGw1LjgtNy44aC04TDUwNy4yLDEzOC44eiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNTIxLjMsMTM4LjhoOGw1LjgtNy44aC04TDUyMS4zLDEzOC44eiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNTM1LjUsMTM4LjhoOGw1LjgtNy44aC04TDUzNS41LDEzOC44eiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNTQ5LjYsMTM4LjhoOGw1LjgtNy44aC04TDU0OS42LDEzOC44eiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNTYzLjgsMTM4LjhoOGw1LjgtNy44aC04TDU2My44LDEzOC44eiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNTc3LjksMTM4LjhoOGw1LjgtNy44aC04TDU3Ny45LDEzOC44eiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNTkyLjEsMTM4LjhoOGw1LjgtNy44aC04TDU5Mi4xLDEzOC44eiIvPgoJCTxwYXRoIGNsYXNzPSJzdDExIiBkPSJNNjA2LjIsMTM4LjhoNy40YzEuMS0xLjQsMS43LTIuOSwxLjctNC41VjEzMUg2MTJMNjA2LjIsMTM4Ljh6Ii8+CgkJPHBhdGggY2xhc3M9InN0MTEiIGQ9Ik00NjcuNCwxMzQuOWMwLjEsMS40LDAuNywyLjcsMS42LDMuOGgzLjVsNS44LTcuOGgtOEw0NjcuNCwxMzQuOXoiLz4KCTwvZz4KPC9nPgo8L3N2Zz4K'
        />
    </div>
</div>
   <script src='https://ajax.googleapis.com/ajax/libs/jquery/3.2.1/jquery.min.js'>
    </script>
      <script type='text/javascript'>
    var element = document.getElementById('hostname');
    element.textContent = document.location.hostname;
    \$.getJSON("https://api.ipify.org?format=json", function(data) {
        \$("#yip").html(data.ip);
    })
    </script>
</body>
</html>
EOF

chown $user /home/$user -R
chgrp $user /home/$user -R
chsh -s /usr/bin/fish #fish shel default
#chsh -s /bin/bash # bash shell default

rm -f /etc/nginx/conf.d/*
cat << EOF > /etc/nginx/conf.d/site-$domain.conf
server {
    listen       80;
    server_name  $domain;

    root   /home/$user/web/public;
    index index.php index.html index.htm;

#    location / {
#        try_files \$uri \$uri/ /index.php?\$args;
#    }
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;

    location = /50x.html {
        root /usr/share/nginx/html;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php-fpm/php-fpm.sock;
        fastcgi_index index.php;
       fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF
echo
echo "----- END CONFIGURATION WEB SERVER ACCESS -----"
echo
chcon -Rt httpd_sys_content_t /home/$user
chmod -R 755 /home/$user
echo
printf "*****  RUN & Configuration CERTBOT SSL *****"
echo

systemctl enable --now snapd.socket
ln -fs /var/lib/snapd/snap /snap
systemctl start --now snapd.socket
snap wait system seed
cat << EOF > snap_permissions.te
module snap_permissions 1.0;
require {
	type systemd_unit_file_t;
	type init_t;
	type snappy_t;
	type syslogd_var_run_t;
	type journalctl_t;
	type snappy_cli_t;
	class dbus send_msg;
	class service start;
	class system status;
	class dir search;
	class capability sys_resource;
	class file map;
}
allow init_t snappy_cli_t:dbus send_msg;
allow journalctl_t init_t:dir search;
allow journalctl_t self:capability sys_resource;
allow journalctl_t syslogd_var_run_t:file map;
allow snappy_cli_t init_t:dbus send_msg;
allow snappy_cli_t init_t:service start;
allow snappy_cli_t systemd_unit_file_t:service start;
allow snappy_t init_t:system status;
EOF
checkmodule -M -m -o snap_permissions.mod snap_permissions.te && rm snap_permissions.te
semodule_package -o snap_permissions.pp -m snap_permissions.mod && rm snap_permissions.mod
semodule -i snap_permissions.pp && rm snap_permissions.pp
snap install --classic certbot

if ! command -v certbot &> /dev/null; then
  ln -s /snap/bin/certbot /usr/bin/certbot
fi
echo
echo "----- END CONFIGURATION WEB SERVER ACCESS -----"
echo
echo
echo
read -p "*****  ADD OPEN PORT 22, 80, 443 *****" -t 5

echo
#firewall
systemctl start firewalld
firewall-cmd --permanent --add-port=22/tcp
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=443/tcp
firewall-cmd --reload
systemctl stop firewalld
systemctl disable firewalld
echo
echo
read -p "*****  Start, resatr systems *****" -t 5

echo
# start at boot
systemctl enable mysqld
systemctl enable php-fpm
systemctl enable nginx

# run them
systemctl restart mysqld
systemctl start php-fpm
systemctl restart $postgresql
systemctl start nginx
echo
echo
read -p "        *****  Exiting from install web apps  *****           " -t 5
clear

echo "██████╗  ██████╗ ███╗   ██╗███████╗";
echo "██╔══██╗██╔═══██╗████╗  ██║██╔════╝";
echo "██║  ██║██║   ██║██╔██╗ ██║█████╗  ";
echo "██║  ██║██║   ██║██║╚██╗██║██╔══╝  ";
echo "██████╔╝╚██████╔╝██║ ╚████║███████╗";
echo "╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝";
echo "                                   ";
read -p "" -t 5
clear
