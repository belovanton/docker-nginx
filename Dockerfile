FROM centos:7
MAINTAINER Anton Belov anton4@bk.ru

# Perform updates
RUN yum -y update; yum clean all

# Install EPEL for owncloud packages
RUN yum -y install epel-release; yum clean all

RUN useradd nginx
RUN usermod -s /sbin/nologin nginx

#Install pagecahe module
ENV NGINX_VERSION 1.10.1
ENV NPS_VERSION 1.11.33.2
RUN 	yum -y install gcc-c++ wget GeoIP-devel GeoIP GeoIP-data unzip make python python-pip curl freetype openssl-devel pcre-devel zlib-devel ca-certificates python-devel &&\
	cd /usr/src &&\
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
         --sbin-path=/usr/sbin --error-log-path=/var/log/nginx/error.log \
	 --with-pcre-jit --with-http_stub_status_module --with-http_realip_module \
	 --with-http_auth_request_module --with-http_addition_module --with-http_ssl_module \
	 --with-ipv6 --with-http_geoip_module --with-http_v2_module --with-http_gzip_static_module \
	 --with-http_sub_module && \
	cd /usr/src/nginx-${NGINX_VERSION}/ && make &&\
	cd /usr/src/nginx-${NGINX_VERSION}/ && make install &&\
	rm -rf /usr/src/ngx_pagespeed-* && rm -rf /usr/src/nginx-* && rm -rf /usr/src/*.tar.gz && rm -rf /usr/src/*.zip &&\
	yum -y remove  gcc-c++  wget unzip  && yum clean all &&\
        mkdir -p /var/nginx/pagespeed_cache

# forward request and error logs to docker log collector
RUN mkdir -p /var/log/nginx/ && chown nginx /var/log/nginx
RUN touch /var/log/nginx/access.log 
RUN touch /var/log/nginx/access.log
RUN ln -sf /dev/stdout /var/log/nginx/access.log && chown nginx /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log  && chown nginx /var/log/nginx/error.log

# Define mountable directories.
VOLUME ["/etc/nginx", "/var/log/nginx", "/var/www/html", "/var/cache/nginx"]

# Define working directory.
WORKDIR /var/www/html

EXPOSE 80
EXPOSE 443
RUN groupadd --gid 33 www-data && useradd --uid 33 --gid 33 www-data
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
