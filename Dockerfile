FROM ubuntu:12.04
MAINTAINER Stian Soiland-Reyes <orcid.org/0000-0001-9842-9718>
ENV UPDATED "Wed Nov 21 14:30:00 GMT 2014"

# Build virtuoso opensource debian package from github
RUN echo "deb http://archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse" >> /etc/apt/sources.list
RUN  apt-get update && \
     DEBIAN_FRONTEND=noninteractive apt-get install -y \
       build-essential debhelper autotools-dev  \
       autoconf automake unzip net-tools \
       libtool flex bison gperf gawk m4 libssl-dev \
       libreadline-gplv2-dev openssl wget >/dev/null
# NOT
#https://github.com/openlink/virtuoso-opensource/archive/develop/7.zip
RUN cd /tmp && \
    wget --no-check-certificate --quiet \
       https://github.com/openlink/virtuoso-opensource/archive/v7.1.0.zip \
       -O /tmp/virtuoso-opensource.zip && \
    unzip -q /tmp/virtuoso-opensource.zip

## Update debian/control for Ubuntu 14.04 LTS
RUN sed -i "s,libreadline5-dev,libreadline-gplv2-dev," /tmp/virtuoso-*/debian/control

# Fix broken debian/changelog - should only be needed for 7.1.0?
COPY files/changelog /tmp/changelog
RUN cp /tmp/changelog /tmp/virtuoso-*/debian/

# Build and install debian package
RUN cd /tmp/virtuoso-*/ && dpkg-buildpackage -us -uc
RUN dpkg -i /tmp/virtuoso-*.deb

# Remove build files and dependencies
RUN rm -rf /tmp/*
RUN apt-get remove -y build-essential debhelper autotools-dev autoconf automake unzip net-tools

# Enable mountable /virtuoso for data storage
RUN mkdir /virtuoso ; sed -i s,/var/lib/virtuoso/db,/virtuoso, /var/lib/virtuoso/db/virtuoso.ini 

# Virtuoso ports
EXPOSE 8890
EXPOSE 1111
# Run virtuoso in the foreground
WORKDIR /var/lib/virtuoso/db
VOLUME ["/virtuoso", "/var/lib/virtuoso/db"]
CMD ["/usr/bin/virtuoso-t", "+wait", "+foreground"]
