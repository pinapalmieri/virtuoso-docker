FROM ubuntu:14.04
MAINTAINER Stian Soiland-Reyes <orcid.org/0000-0001-9842-9718>

# openjdk 6 hard-coded to resolve 
# ambiguity in build dependency
# https://github.com/openlink/virtuoso-opensource/issues/342
# FIXME: Is openjdk-6-jdk still needed?
ENV BUILD_DEPS openjdk-6-jdk unzip wget net-tools build-essential
ENV URL https://github.com/openlink/virtuoso-opensource/archive/stable/7.zip

# Build virtuoso opensource debian package from github
RUN echo "deb http://archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse" >> /etc/apt/sources.list
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y $BUILD_DEPS && \
    cd /tmp && \
    wget --no-check-certificate --quiet $URL \
       -O /tmp/virtuoso-opensource.zip && \
    unzip -q /tmp/virtuoso-opensource.zip && \
    cd /tmp/virtuoso-*/ && \
    deps=$(dpkg-checkbuilddeps 2>&1 | sed 's/.*: //' | sed 's/([^)]*)//g') && \
    apt-get install -y $deps && \
    dpkg-buildpackage -us -uc && \
    apt-get remove -y --purge $BUILD_DEPS $deps && \
    apt-get autoremove --purge -y && \
    cd /tmp && \
    dpkg -i virtuoso-opensource*deb virtuoso-server*.deb virtuoso-minimal_*.deb virtuoso-server*.deb  libvirtodbc*.deb || apt-get install -f -y && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*

RUN ln -s /usr/bin/isql-vt /usr/local/bin/isql


# Enable mountable /virtuoso for data storage
RUN rm -rf /var/lib/virtuoso-opensource-7/db 
RUN mkdir /virtuoso
RUN ln -s /var/lib/virtuoso-opensource-7/db /virtuoso
#RUN mkdir /virtuoso ; sed -i s,/var/lib/virtuoso-opensource-7/db,/virtuoso, /etc/virtuoso-opensource-7/virtuoso.ini 
# And /staging for loading data
RUN mkdir /staging ; sed -i '/DirsAllowed/ s:$:,/staging:' /etc/virtuoso-opensource-7/virtuoso.ini

COPY start-virtuoso.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/start-virtuoso.sh

# Virtuoso ports
EXPOSE 8890
EXPOSE 1111
WORKDIR /virtuoso
# Run virtuoso in the foreground
VOLUME ["/virtuoso", "/staging", "/etc/virtuoso-opensource-7"]
#CMD ["/usr/bin/virtuoso-t", "+wait", "+foreground"]
CMD ["/usr/local/bin/start-virtuoso.sh"]

