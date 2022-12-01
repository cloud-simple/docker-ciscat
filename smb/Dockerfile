FROM alpine:3.17

ENV TZ="UTC"

RUN apk --update --no-cache add \
    bash \
    coreutils \
    jq \
    samba \
    samba-common-tools \
    shadow \
    tzdata \
    yq \
  && rm -rf /tmp/*

RUN echo "alias ll='ls -la'" >> /root/.bashrc

COPY entrypoint.sh /entrypoint.sh

EXPOSE 445
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "smbd", "-F", "--no-process-group", "--configfile=/etc/samba/smb.conf" ]

HEALTHCHECK --interval=30s --timeout=10s CMD smbclient -L \\localhost -U % -m SMB3
