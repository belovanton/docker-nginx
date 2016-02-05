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
	ca-certificates curl  \
	wget pkg-config &&\
        apt-get clean && \
        rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /download/directory

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && apt-get clean && \
	apt-get -y install \	
	python python-pip libgeoip-dev python-dev nginx-extras libfreetype6 libfontconfig1 \
	build-essential zlib1g-dev libpcre3 libpcre3-dev unzip libssl-dev &&\
	apt-get clean && \
	rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/* /download/directory

#Install pagecahe module
ENV NGINX_VERSION 1.9.10
ENV NPS_VERSION 1.10.33.4
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
	 --with-pcre-jit --with-http_stub_status_module --with-http_realip_module \
	 --with-http_auth_request_module --with-http_addition_module --with-http_ssl_module \
	 --with-ipv6 --with-http_geoip_module --with-http_v2_module --with-http_gzip_static_module \
	 --with-http_sub_module && \
	cd /usr/src/nginx-${NGINX_VERSION}/ && make &&\
	cd /usr/src/nginx-${NGINX_VERSION}/ && sudo make install &&\
        sed -i 's|/usr/sbin/nginx|/home/nginx|g' /etc/init.d/nginx && \
        rm /usr/sbin/nginx &&\
        mkdir -p /var/nginx/pagespeed_cache


# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Define mountable directories.
VOLUME ["/etc/nginx", "/var/log/nginx", "/var/www/html", "/var/cache/nginx"]

# Define working directory.
WORKDIR /var/www/html

EXPOSE 80
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
