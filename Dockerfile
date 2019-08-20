FROM odoo:12.0

ENV PYTHON_BIN=python3 \
    SERVICE_BIN=odoo-bin

# Install APT dependencies
ADD sources/apt.txt /opt/sources/apt.txt
USER root
RUN apt update \
    && awk '! /^ *(#|$)/' /opt/sources/apt.txt | xargs -r apt install -yq
ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64.deb /opt/sources/dumb-init.deb
#RUN gdebi /opt/sources/dumb-init.deb
RUN dpkg -i /opt/sources/dumb-init.deb
USER odoo

User 0

# If the folders are created with "RUN mkdir" command, they will belong to root
# instead of odoo! Hence the "RUN /bin/bash -c" trick.
RUN /bin/bash -c "mkdir -p /opt/odoo/{etc,sources/odoo,additional_addons,data,ssh}"


ADD sources/odoo.conf /opt/odoo/etc/odoo.conf
ADD auto_addons /opt/odoo/auto_addons

# Startup script for custom setup
ADD sources/startup.sh /opt/scripts/startup.sh

# Provide read/write access to odoo group (for host user mapping). This command
# must run before creating the volumes since they become readonly until the
# container is started.
RUN chmod -R 775 /opt/odoo && chown -R odoo:odoo /opt/odoo

VOLUME [ \
    "/opt/odoo/etc", \
    "/opt/odoo/additional_addons", \
    "/opt/odoo/data", \
    "/opt/odoo/ssh", \
    "/opt/scripts" \
    ]

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

# Use dumb-init as init system to launch the boot script
ADD bin/boot /usr/bin/boot
ENTRYPOINT [ "/usr/bin/dumb-init", "/usr/bin/boot" ]
CMD [ "help" ]
USER odoo