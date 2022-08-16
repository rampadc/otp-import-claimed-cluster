FROM quay.io/openshift/origin-cli:v3.11

RUN yum install -y gettext

COPY main.sh main.sh
COPY auto-import-secret.yaml auto-import-secret.yaml
COPY managed-cluster.yaml managed-cluster.yaml
RUN chmod +x main.sh
CMD ["./main.sh"]