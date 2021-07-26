FROM centos:7

RUN yum install -y openssl
COPY rootCA.crt /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust
