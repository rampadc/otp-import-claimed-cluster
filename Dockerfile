FROM quay.io/openshift/origin-cli:4.10

COPY main.sh main.sh
RUN chmod +x main.sh
CMD ["./main.sh"]