FROM debian:bookworm-slim

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
       openvpn libpam-radius-auth freeradius-utils easy-rsa \
    && rm -rf /var/lib/apt/lists/*

COPY pam-openvpn /etc/pam.d/openvpn
COPY scripts/radius-accounting /usr/local/sbin/radius-accounting
COPY scripts/entrypoint /usr/local/sbin/openvpn-entrypoint
RUN chmod 0755 /usr/local/sbin/radius-accounting /usr/local/sbin/openvpn-entrypoint \
    && mkdir -p /etc/openvpn

ENTRYPOINT ["/usr/local/sbin/openvpn-entrypoint"]
