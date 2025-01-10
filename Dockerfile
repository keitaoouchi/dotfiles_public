# Use official Ubuntu image
FROM ubuntu:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install minimal dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -s /bin/bash user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user

# Copy start.sh
COPY start.sh /home/user/start.sh
RUN chmod +x /home/user/start.sh

# Set working directory and user
WORKDIR /home/user
USER user

# Set entrypoint
ENTRYPOINT ["/home/user/start.sh"]
