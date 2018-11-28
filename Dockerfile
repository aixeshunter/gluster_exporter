FROM   gluster/gluster-centos:gluster3u12_centos7
LABEL  maintainer="Aixes Hunter <aixeshunter@gmail.com>"

EXPOSE 9189
EXPOSE 24007
EXPOSE 24009-24108

# Copy gluster_exporter
COPY gluster_exporter /usr/bin/gluster_exporter

RUN chmod 775 /usr/bin/gluster_exporter

#RUN /usr/bin/gluster_exporter
ENTRYPOINT [ "/usr/bin/gluster_exporter" ]
