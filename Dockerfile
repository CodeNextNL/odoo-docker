FROM debian:stretch
LABEL maintainer="codeNext <info@codenext.nl>"

# todo: FROM debian:stretch change to liter versions

ENV PYTHON_BIN=python3 \
    SERVICE_BIN=odoo-bin \
    ODOO_VERSION=12.0 \
    OPENERP_SERVER=/opt/odoo/etc/odoo.conf \
    ODOO_SOURCE_DIR=/opt/odoo \
    ADDONS_DIR=/opt/odoo/addons \
    BACKUPS_DIR=/opt/odoo/backups \
    LOGS_DIR=/opt/odoo/logs \
    ODOO_DATA_DIR=/opt/odoo/data

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
#ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64.deb /opt/sources/dumb-init.deb
RUN set -x; \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    dirmngr \
    dpkg \
    fonts-noto-cjk \
    gdebi \
    git \
    gnupg \
    libldap2-dev \
    libsasl2-dev \
    libssl1.0-dev \
    libxslt-dev \
    libzip-dev \
    node-less \
    python3-dev \
    python3-pip \
    python3-pyldap \
    python3-qrcode \
    python3-renderpm \
    python3-setuptools \
    python3-vobject \
    python3-watchdog \
    sudo \
    xz-utils \
    && curl -o wkhtmltox.deb -sSL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.stretch_amd64.deb \
    && curl -o dumb-init.deb -sSL https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64.deb \
    && echo '7e35a63f9db14f93ec7feeb0fce76b30c08f2057 wkhtmltox.deb' | sha1sum -c - \
    && dpkg --force-depends -i wkhtmltox.deb\
    && dpkg -i dumb-init.deb \
    && apt-get -y install -f --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* wkhtmltox.deb dumb-init.deb

# install latest postgresql-client
RUN set -x; \
    echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' > etc/apt/sources.list.d/pgdg.list \
    && export GNUPGHOME="$(mktemp -d)" \
    && repokey='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --armor --export "${repokey}" | apt-key add - \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update \
    && apt-get install -y postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install rtlcss (on Debian stretch)
RUN set -x;\
    echo "deb http://deb.nodesource.com/node_8.x stretch main" > /etc/apt/sources.list.d/nodesource.list \
    && export GNUPGHOME="$(mktemp -d)" \
    && repokey='9FD3B784BC1C6FC31A8A0A1C1655A0AB68576280' \
    && gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "${repokey}" \
    && gpg --armor --export "${repokey}" | apt-key add - \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && apt-get update \
    && apt-get install -y nodejs \
    && npm install -g rtlcss \
    && rm -rf /var/lib/apt/lists/*

# Install Odoo
RUN git clone --depth=1 -b ${ODOO_VERSION} https://github.com/odoo/odoo.git $ODOO_SOURCE_DIR && \
    adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --group odoo && \
    chown -R odoo:odoo $ODOO_SOURCE_DIR && \
    mkdir -p $ODOO_SOURCE_DIR && chown odoo $ODOO_SOURCE_DIR && \
    mkdir -p $ADDONS_DIR/extra && chown -R odoo $ADDONS_DIR && \
    mkdir -p $ODOO_DATA_DIR && chown odoo:odoo $ODOO_DATA_DIR && \
    mkdir -p /mnt/config && chown odoo /mnt/config && \
    mkdir -p $BACKUPS_DIR && chown odoo $BACKUPS_DIR && \
    mkdir -p $LOGS_DIR && chown odoo $LOGS_DIR  && \
    mkdir -p $ODOO_SOURCE_DIR/etc && chown odoo:odoo $ODOO_SOURCE_DIR/etc  && \
    mkdir -p $ODOO_SOURCE_DIR/additional_addons && chown odoo:odoo $ODOO_SOURCE_DIR/additional_addons && \
    mkdir -p $ODOO_SOURCE_DIR/auto_addons && chown odoo:odoo $ODOO_SOURCE_DIR/auto_addons

RUN pip3 install -r https://github.com/odoo/odoo/raw/${ODOO_VERSION}/requirements.txt

# Startup script for custom setup
ADD sources/startup.sh /opt/scripts/startup.sh
ADD sources/odoo.conf /opt/odoo/etc/odoo.conf
ADD auto_addons /opt/odoo/auto_addons

# Use README for the help & man commands
ADD README.md /usr/share/man/man.txt
# Remove anchors and links to anchors to improve readability
RUN sed -i '/^<a name=/ d' /usr/share/man/man.txt
RUN sed -i -e 's/\[\^\]\[toc\]//g' /usr/share/man/man.txt
RUN sed -i -e 's/\(\[.*\]\)(#.*)/\1/g' /usr/share/man/man.txt
# For help command, only keep the "Usage" section
RUN from=$( awk '/^## Usage/{ print NR; exit }' /usr/share/man/man.txt ) && \
    from=$(expr $from + 1) && \
    to=$( awk '/^    \$ docker-compose up/{ print NR; exit }' /usr/share/man/man.txt ) && \
    head -n $to /usr/share/man/man.txt | \
    tail -n +$from | \
    tee /usr/share/man/help.txt > /dev/null

# custom
RUN usermod -aG sudo odoo
ENV ODOO_RC /opt/odoo/etc/odoo.conf
ADD auto_addons/oca_dependencies.txt /opt/odoo/additional_addons

# Expose Odoo services
EXPOSE 8069 8071

# Use dumb-init as init system to launch the boot script
ADD bin/boot /usr/bin/boot
ENTRYPOINT [ "/usr/bin/dumb-init", "/usr/bin/boot" ]
CMD [ "help" ]
USER odoo