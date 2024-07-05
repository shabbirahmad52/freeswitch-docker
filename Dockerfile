# Use the official Ubuntu 22.04 as a base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && apt-get install --yes \
    build-essential \
    pkg-config \
    uuid-dev \
    zlib1g-dev \
    libjpeg-dev \
    libsqlite3-dev \
    libcurl4-openssl-dev \
    libpcre3-dev \
    libspeexdsp-dev \
    libldns-dev \
    libedit-dev \
    libtiff5-dev \
    yasm \
    libopus-dev \
    libsndfile1-dev \
    unzip \
    libavformat-dev \
    libswscale-dev \
    liblua5.2-dev \
    liblua5.2-0 \
    cmake \
    libpq-dev \
    unixodbc-dev \
    autoconf \
    automake \
    ntpdate \
    libxml2-dev \
    libpq-dev \
    libpq5 \
    sngrep \
    lua5.2 \
    lua5.2-doc \
    libreadline-dev \
    git \
    wget \
    curl \
    python3-pip \
    sngrep \
    openssh-client \
    nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip3 install pymongo psycopg2 mysql-connector-python greenswitch

# Install spandsp
RUN git clone https://github.com/freeswitch/spandsp.git /usr/local/src/spandsp && \
    cd /usr/local/src/spandsp && \
    git checkout 0d2e6ac && \
    ./bootstrap.sh && ./configure && make && make install && \
    cd / && rm -rf /usr/local/src/spandsp

# Install Sofia-sip
RUN cd /usr/local/src && \
    git clone https://github.com/freeswitch/sofia-sip.git && \
    cd sofia-sip && \
    ./bootstrap.sh && \
    ./configure && \
    make && \
    make install && \
    cd / && rm -rf /usr/local/src/sofia-sip

# Download and extract FreeSWITCH
RUN cd /usr/local/src && \
    wget https://files.freeswitch.org/releases/freeswitch/freeswitch-1.10.10.-release.tar.gz && \
    tar -zxvf freeswitch-1.10.10.-release.tar.gz && \
    rm freeswitch-1.10.10.-release.tar.gz

# Install Lua Module
RUN cp /usr/include/lua5.2/*.h /usr/local/src/freeswitch-1.10.10.-release/src/mod/languages/mod_lua/ && \
    ln -s /usr/lib/x86_64-linux-gnu/liblua5.2.so /usr/lib/x86_64-linux-gnu/liblua.so

# FreeSWITCH 1.10.10 Installation
WORKDIR /usr/local/src/freeswitch-1.10.10.-release

# Modify modules.conf to remove mod_signalwire and mod_verto
RUN sed -i 's/mod_signalwire//g' modules.conf && \
    sed -i 's/mod_verto//g' modules.conf

# Compile and install FreeSWITCH
RUN ./configure --enable-core-odbc-support --enable-core-pgsql-support && \
    make && \
    make install && \
    make cd-sounds-install && \
    make cd-moh-install

# Setup softlinks and paths
RUN ln -s /usr/local/freeswitch/conf /etc/freeswitch && \
    ln -s /usr/local/freeswitch/bin/fs_cli /usr/bin/fs_cli && \
    ln -s /usr/local/freeswitch/bin/freeswitch /usr/sbin/freeswitch

# Add non-root less privileged system user for running FreeSWITCH daemon
RUN groupadd freeswitch && \
    adduser --quiet --system --home /usr/local/freeswitch --gecos 'FreeSWITCH open source softswitch' --ingroup freeswitch freeswitch --disabled-password && \
    chown -R freeswitch:freeswitch /usr/local/freeswitch/ && \
    chmod -R ug=rwX,o= /usr/local/freeswitch/ && \
    chmod -R u=rwx,g=rx /usr/local/freeswitch/bin/*

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose necessary ports
EXPOSE 5060 5061 5080 5081

# Start FreeSWITCH
ENTRYPOINT ["/entrypoint.sh"]

