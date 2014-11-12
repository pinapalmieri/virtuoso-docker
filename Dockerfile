FROM ubuntu:14.04
MAINTAINER Stian Soiland-Reyes <orcid.org/0000-0001-9842-9718>
ENV UPDATED "Wed Nov 12 12:26:46 GMT 2014"

# Build virtuoso opensource debian package from github
RUN echo "deb http://us.archive.ubuntu.com/ubuntu/ precise-backports main restricted universe multiverse" >> /etc/apt/sources.list
RUN apt-get update
RUN apt-get install -y build-essential debhelper autotools-dev autoconf automake unzip wget net-tools > /dev/null
RUN apt-get install -y libtool flex bison gperf gawk m4 libssl-dev libreadline-dev openssl > /dev/null
RUN wget --no-check-certificate -q https://github.com/openlink/virtuoso-opensource/archive/stable/7.zip -O virtuoso-opensource.zip
RUN unzip -q virtuoso-opensource.zip
RUN cd virtuoso-opensource-develop-7/ && dpkg-buildpackage -us -uc
RUN cd .. && dpkg -i virtuoso-opensource_7.1_amd64.deb

# Remove build files
RUN rm -rf virtuoso-opensource.zip virtuoso-opensource-develop-7/ virtuoso-opensource_7.1_amd64.deb virtuoso-opensource_7.1.dsc
RUN rm -rf virtuoso-opensource_7.1.tar.gz virtuoso-opensource-develop-7 virtuoso-opensource_7.1_amd64.changes
RUN apt-get remove -y build-essential debhelper autotools-dev autoconf automake unzip wget net-tools

# Run virtuoso in the foreground
EXPOSE 8890
EXPOSE 1111
WORKDIR /var/lib/virtuoso/db
CMD ["/usr/bin/virtuoso-t", "+wait", "+foreground"]
