FROM tomcat:9-jre11

ENV TZ="UTC"

RUN apt-get update \
 && apt-get install -y --no-install-recommends unzip vim iproute2 \
 && echo ":colo elflord" >> /root/.vimrc

COPY entrypoint.sh /entrypoint.sh

EXPOSE 80
VOLUME [ "/data" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "catalina.sh", "run" ]

# TODO: create HEALTHCHECK for `tomcat`, the following is an example one for `samba`
# HEALTHCHECK --interval=30s --timeout=10s CMD smbclient -L \\localhost -U % -m SMB3
