FROM ubuntu:latest 
MAINTAINER Anton Belov anton4@bk.ru

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive
# Use source.list with all repositories and Yandex mirrors.
ADD sources.list /etc/apt/sources.list
RUN sed -i 's|://.*\..*\.com|://ru.archive.ubuntu.com|' /etc/apt/sources.list &&\
    echo 'force-unsafe-io' | tee /etc/dpkg/dpkg.cfg.d/02apt-speedup &&\
    echo 'DPkg::Post-Invoke {"/bin/rm -f /var/cache/apt/archives/*.deb || true";};' | tee /etc/apt/apt.conf.d/no-cache &&\
    echo 'Acquire::http {No-Cache=True;};' | tee /etc/apt/apt.conf.d/no-http-cache

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && apt-get clean && \
	apt-get -y install \
	python-setuptools \
	ca-certificates curl  \
	wget pkg-config &&\
        apt-get clean && \
        rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /download/directory

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && apt-get clean && \
	apt-get -y install \	
	python python-pip python-dev nginx-extras libfreetype6 libfontconfig1 \
	build-essential zlib1g-dev libpcre3 libpcre3-dev unzip libssl-dev &&\
	apt-get clean && \
	rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /download/directory

#Install pagecahe module
ENV NGINX_VERSION 1.9.5
ENV NPS_VERSION 1.9.32.10
RUN 	cd /usr/src &&\
	cd /usr/src &&\
	cd /usr/src && wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-beta.zip &&\
	cd /usr/src && unzip release-${NPS_VERSION}-beta.zip &&\
	cd /usr/src/ngx_pagespeed-release-${NPS_VERSION}-beta/ && pwd && wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz &&\
	cd /usr/src/ngx_pagespeed-release-${NPS_VERSION}-beta/ && tar -xzvf ${NPS_VERSION}.tar.gz &&\
	cd /usr/src &&\
	cd /usr/src && wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz &&\
	cd /usr/src && tar -xvzf nginx-${NGINX_VERSION}.tar.gz &&\
	cd /usr/src/nginx-${NGINX_VERSION}/ && ./configure --add-module=/usr/src/ngx_pagespeed-release-${NPS_VERSION}-beta \ 
         --prefix=/usr/local/share/nginx --conf-path=/etc/nginx/nginx.conf \
         --sbin-path=/usr/local/sbin --error-log-path=/var/log/nginx/error.log \
	 --with-http_ssl_module && \
	cd /usr/src/nginx-${NGINX_VERSION}/ && make &&\
	cd /usr/src/nginx-${NGINX_VERSION}/ && sudo make install &&\
        sed -i 's|/usr/sbin/nginx|/home/nginx|g' /etc/init.d/nginx && \
        rm /usr/sbin/nginx &&\
        mkdir -p /var/nginx/pagespeed_cache

# Magento Initialization and Startup Script
ADD /scripts /scripts
ADD /config /config
RUN chmod 755 /scripts/*.sh

# Supervisor Config
RUN /usr/bin/easy_install supervisor &&\
    /usr/bin/easy_install supervisor-stdout
ADD /config/supervisor/supervisord.conf /etc/supervisord.conf

VOLUME /var/www
EXPOSE 80

CMD ["/bin/bash", "/scripts/start.sh"]
