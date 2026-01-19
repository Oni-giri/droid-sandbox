# Dev container with Python, Node.js/TypeScript, and Droid CLI
# Based on Ubuntu 24.04 LTS (Noble Numbat)
FROM docker.io/library/ubuntu:24.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages and xdg-utils (required for Droid)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    ca-certificates \
    gnupg \
    build-essential \
    xdg-utils \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

# Install Python 3 and pip
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js LTS (v22.x) from NodeSource
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install common global npm packages for TypeScript development
RUN npm install -g typescript ts-node @types/node @anthropic-ai/claude-code

# Install Droid CLI (Factory.ai) globally
ARG DROID_VERSION
RUN curl -fsSL https://app.factory.ai/cli > /tmp/install_droid.sh \
    && if [ -n "$DROID_VERSION" ]; then \
        sed -i "s/VER=\".*\"/VER=\"$DROID_VERSION\"/" /tmp/install_droid.sh; \
    fi \
    && sh /tmp/install_droid.sh \
    && mv /root/.local/bin/droid /usr/local/bin/droid \
    && chmod +x /usr/local/bin/droid \
    && rm /tmp/install_droid.sh

# Set up a non-root user for development
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Remove ubuntu user (UID 1000) if it exists, then create dev user with UID 1000
RUN if id -u ubuntu >/dev/null 2>&1; then userdel -r ubuntu 2>/dev/null || true; fi \
    && groupadd --gid $USER_GID $USERNAME 2>/dev/null || true \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /home/$USERNAME/.local/bin \
    && chown -R $USERNAME:$USERNAME /home/$USERNAME

# Add local bin to PATH
ENV PATH="/home/$USERNAME/.local/bin:$PATH"

# Switch to non-root user
USER $USERNAME
WORKDIR /home/$USERNAME/workspace

# Set default shell
CMD ["/bin/bash"]
