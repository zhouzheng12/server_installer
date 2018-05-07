#!/bin/bash
function pre_install(){
    mkdir -p $BASE_DIR/server/php
    source ./dep_env.sh
}

function post_install(){
    cd ..
    cp ./php-7.2.5/php.ini-production $BASE_DIR/server/php/etc/php.ini
    #adjust php.ini
    extension_dir="$BASE_DIR/server/php/bin/php-config --extension-dir"
    sed -i 's#; extension_dir = \"\.\/\"#extension_dir = "'$extension_dir'"#'  $BASE_DIR/server/php/etc/php.ini
    sed -i 's/post_max_size = 8M/post_max_size = 64M/g' $BASE_DIR/server/php/etc/php.ini
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/g' $BASE_DIR/server/php/etc/php.ini
    sed -i 's/;date.timezone =/date.timezone = PRC/g' $BASE_DIR/server/php/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g' $BASE_DIR/server/php/etc/php.ini
    sed -i 's/max_execution_time = 30/max_execution_time = 300/g' $BASE_DIR/server/php/etc/php.ini
    #adjust php-fpm
    cp $BASE_DIR/server/php/etc/php-fpm.conf.default $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,user = nobody,user=www,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,group = nobody,group=www,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,^pm.min_spare_servers = 1,pm.min_spare_servers = 5,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,^pm.max_spare_servers = 3,pm.max_spare_servers = 35,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,^pm.max_children = 5,pm.max_children = 100,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,^pm.start_servers = 2,pm.start_servers = 20,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,;pid = run/php-fpm.pid,pid = run/php-fpm.pid,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,listen = 127.0.0.1:9000,listen = [::]:9000,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,;error_log = log/php-fpm.log,error_log = '$BASE_DIR'/server/php/var/log/php-fpm.log,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    sed -i 's,;slowlog = log/$pool.log.slow,slowlog = '$BASE_DIR'/server/php/var/log/\$pool.log.slow,g'   $BASE_DIR/server/php/etc/php-fpm.conf
    #self start
    cp $BASE_DIR/server/php/etc/php-fpm.d/www.conf.default $BASE_DIR/server/php/etc/php-fpm.d/www.conf
    sed -i 's,listen = 127.0.0.1:9000,listen = 9000,g' $BASE_DIR/server/php/etc/php-fpm.d/www.conf
    install -v -m755 ./php-7.1.3/sapi/fpm/init.d.php-fpm  /etc/init.d/php-fpm
    /etc/init.d/php-fpm start
}

function install_server(){
    rm -rf php-7.2.5
    if [ ! -f php-7.2.5.tar.gz ];then
        wget http://mirrors.sohu.com/php/php-7.2.5.tar.gz  -O  php-7.2.5.tar.gz
    fi
    tar zxvf php-7.2.5.tar.gz
    cd php-7.2.5
    ./configure --prefix=$BASE_DIR/server/php \
    --with-config-file-path=$BASE_DIR/server/php/etc \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --enable-fpm \
    --enable-static \
    --enable-maintainer-zts \
    --enable-inline-optimization \
    --enable-sockets \
    --enable-wddx \
    --enable-zip \
    --enable-calendar \
    --enable-bcmath \
    --enable-soap \
    --with-zlib \
    --with-iconv \
    --with-gd \
    --with-xmlrpc \
    --enable-mbstring \
    --without-sqlite \
    --enable-ftp \
    --with-freetype-dir=/usr/local/freetype.2.1.10 \
    --disable-ipv6 \
    --disable-debug \
    --with-openssl \
    --disable-maintainer-zts \
    --enable-intl

    CPU_NUM=$(cat /proc/cpuinfo | grep processor | wc -l)
    if [ $CPU_NUM -gt 1 ];then
        make ZEND_EXTRA_LIBS='-liconv' -j$CPU_NUM
    else
        make ZEND_EXTRA_LIBS='-liconv'
    fi
    make install
}
function remove_server(){
    /etc/init.d/php-fpm stop
    rm -rf  $BASE_DIR/server/php
}