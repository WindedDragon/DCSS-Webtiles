FROM centos:7

ENV container docker

RUN groupadd -r -g 1000 crawl && useradd -r -m -g crawl -u 1000 crawl


RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

# Setup gosu for easier command execution
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu
	
	
RUN yum install -yy gcc gcc-c++ make bison flex ncurses-devel compat-lua-devel \
      sqlite-devel zlib-devel pkgconfig SDL-devel SDL_image-devel libpng-devel \
      freetype-devel dejavu-sans-fonts dejavu-sans-mono-fonts epel-release
RUN yum install -yy python-pip git 
RUN yum update -yy

# clone from github latest crawl version
RUN git clone https://github.com/crawl/crawl.git && cd /crawl \
	&& git checkout 0.20.1 \
        && git submodule update --init \
	&& mkdir -p /crawl/crawl-ref/source/rcs \
	&& mkdir -p /crawl/crawl-ref/source/saves
# install pip and tornado for web server
RUN pip install -U pip && pip install 'tornado>=3.0,<4.0' 

# make webtile version
RUN cd /crawl/crawl-ref/source && make WEBTILES=y

COPY docker-entrypoint.sh /entrypoint.sh
RUN chown -R crawl:crawl /entrypoint.sh \
	&& chmod 777 /entrypoint.sh \
	&& chown -R crawl:crawl /crawl
 
CMD ["/usr/sbin/init"]

WORKDIR /crawl/crawl-ref/source
VOLUME /crawl
VOLUME /crawl/crawl-ref/source/saves
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]

#USER crawl
CMD ["python", "./webserver/server.py"]	
