FROM ubuntu:14.04
MAINTAINER Stian Soiland-Reyes <orcid.org/0000-0001-9842-9718>

# Build virtuoso opensource debian package from github
RUN echo "deb http://archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse" >> /etc/apt/sources.list
RUN  apt-get update && \
     DEBIAN_FRONTEND=noninteractive apt-get install -y \
       build-essential debhelper autotools-dev  \
       autoconf automake unzip net-tools \
       libtool flex bison gperf gawk m4 libssl-dev \
       libreadline-dev openssl wget >/dev/null && \
    cd /tmp && \
    wget --no-check-certificate --quiet \
    https://github.com/openlink/virtuoso-opensource/archive/develop/7.zip \
       -O /tmp/virtuoso-opensource.zip && \
    unzip -q /tmp/virtuoso-opensource.zip && \
    cd /tmp/virtuoso-*/ && dpkg-buildpackage -us -uc && \
    dpkg -i /tmp/virtuoso-*.deb && \
    rm -rf /tmp/* &&\
    DEBIAN_FRONTEND=noninteractive apt-get remove -y --purge build-essential debhelper autotools-dev \ 
        flex bison autoconf automake wget unzip net-tools gcc && \
    DEBIAN_FRONTEND=noninteractive apt-get -y autoremove


# Enable mountable /virtuoso for data storage
RUN mkdir /virtuoso ; sed -i s,/var/lib/virtuoso/db,/virtuoso, /var/lib/virtuoso/db/virtuoso.ini 
# And /staging for loading data
RUN mkdir /staging ; sed -i '/DirsAllowed/ s:$:,/staging:' /var/lib/virtuoso/db/virtuoso.ini

COPY start-virtuoso.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/start-virtuoso.sh

# Virtuoso ports
EXPOSE 8890
EXPOSE 1111
# Run virtuoso in the foreground
WORKDIR /var/lib/virtuoso/db
VOLUME ["/virtuoso", "/staging", "/var/lib/virtuoso/db"]
#CMD ["/usr/bin/virtuoso-t", "+wait", "+foreground"]
CMD ["/usr/local/bin/start-virtuoso.sh"]

