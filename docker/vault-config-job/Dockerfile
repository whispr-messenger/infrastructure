FROM hashicorp/vault:1.15.2

RUN apk add --no-cache curl jq 

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

ENTRYPOINT ["/bin/sh", "-c"]
