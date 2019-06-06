FROM ubuntu:16.04
MAINTAINER james@gauntlt.org

ARG ARACHNI_VERSION=arachni-1.5.1-0.5.12

# Install Ruby and other OS stuff
RUN apt-get update && \
    apt-get install -y build-essential \
      bzip2 \
      ca-certificates \
      curl \
      gcc \
      git \
      libcurl3 \
      libcurl4-openssl-dev \
      wget \
      zlib1g-dev \
      libfontconfig \
      libxml2-dev \
      libxslt1-dev \
      make \
      python-pip \
      python2.7 \
      python2.7-dev \
      ruby \
      ruby-dev \
      ruby-bundler \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'gem: --no-rdoc --no-ri' > /etc/gemrc

# Install Gauntlt
RUN gem install rake \
  && gem install ffi -v 1.9.18 \
  && gem install gauntlt

# Install Attack tools
WORKDIR /opt

# osquery!
ARG OSQUERY_VERSION=3.3.2
ARG OSQUERY_HASH=05b0b15bd44e6a85813dd92a567c371031938aedbcd2e64d32229a3ca0c2d509

# shasum expects two spaces or space* for the shasum file
RUN curl "https://pkg.osquery.io/linux/osquery-${OSQUERY_VERSION}_1.linux_x86_64.tar.gz" \
        -o osquery.tar.gz \
      && echo "${OSQUERY_HASH} *osquery.tar.gz" > check.sha \
      && shasum -a 256 -c check.sha \
      && tar xzvf osquery.tar.gz > /dev/null \
      && mv usr/bin/* /usr/local/bin

# arachni
RUN wget https://github.com/Arachni/arachni/releases/download/v1.5.1/${ARACHNI_VERSION}-linux-x86_64.tar.gz && \
    tar xzvf ${ARACHNI_VERSION}-linux-x86_64.tar.gz > /dev/null && \
    mv ${ARACHNI_VERSION} /usr/local && \
    ln -s /usr/local/${ARACHNI_VERSION}/bin/* /usr/local/bin/

# Nikto
RUN apt-get update && \
    apt-get install -y libtimedate-perl \
      libnet-ssleay-perl && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth=1 https://github.com/sullo/nikto.git && \
    cd nikto/program && \
    echo "EXECDIR=/opt/nikto/program" >> nikto.conf && \
    ln -s /opt/nikto/program/nikto.conf /etc/nikto.conf && \
    chmod +x nikto.pl && \
    ln -s /opt/nikto/program/nikto.pl /usr/local/bin/nikto

# sqlmap
WORKDIR /opt
ENV SQLMAP_PATH /opt/sqlmap/sqlmap.py
RUN git clone --depth=1 https://github.com/sqlmapproject/sqlmap.git

# dirb
ENV DIRB_WORDLISTS /opt/dirb222/wordlists

COPY vendor/dirb222.tar.gz dirb222.tar.gz

RUN tar xvfz dirb222.tar.gz > /dev/null && \
    cd dirb222 && \
    chmod 755 ./configure && \
    ./configure && \
    make && \
    ln -s /opt/dirb222/dirb /usr/local/bin/dirb

# nmap
RUN apt-get update && \
    apt-get install -y nmap && \
    rm -rf /var/lib/apt/lists/*

# sslyze
RUN pip install sslyze==1.3.4
ENV SSLYZE_PATH /usr/local/bin/sslyze

ENTRYPOINT [ "/usr/local/bin/gauntlt" ]
