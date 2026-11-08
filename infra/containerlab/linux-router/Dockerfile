FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    frr lldpd openssh-server iproute2 iputils-ping tcpdump ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -s /bin/bash -G adm lab \
    && mkdir -p /run/sshd /home/lab/.ssh \
    && chown -R lab:lab /home/lab/.ssh \
    && chmod 700 /home/lab/.ssh \
    && sed -i 's/^zebra=no/zebra=yes/; s/^staticd=no/staticd=yes/' /etc/frr/daemons \
    && printf '\nPasswordAuthentication no\nPermitRootLogin no\nPubkeyAuthentication yes\n' >> /etc/ssh/sshd_config
COPY entrypoint.sh /usr/local/bin/router-entrypoint
RUN chmod +x /usr/local/bin/router-entrypoint
ENTRYPOINT ["/usr/local/bin/router-entrypoint"]
