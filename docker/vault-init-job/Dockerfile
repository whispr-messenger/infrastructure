FROM hashicorp/vault:1.15.2

# Install kubectl and yq
USER root

# Install kubectl - use fixed version to avoid network issues
RUN apk add --no-cache curl && \
    curl -LO "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install yq
RUN curl -L "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Copy vault-init script
COPY vault-init.sh /usr/local/bin/vault-init.sh
RUN chmod +x /usr/local/bin/vault-init.sh

# Switch back to vault user
USER vault

# Verify installations
RUN vault version && kubectl version --client && yq --version

# Set the entrypoint to our script
ENTRYPOINT ["/usr/local/bin/vault-init.sh"]
