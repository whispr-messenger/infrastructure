FROM hashicorp/vault:1.15.2

RUN apk add --no-cache curl jq 

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

ENTRYPOINT ["/bin/sh", "-c"]
