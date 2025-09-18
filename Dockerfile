FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required build and runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    update-ca-certificates && \
    apt-get install -y --no-install-recommends \
        build-essential \
        binutils \
        bash \
        cmake \
        findutils \
        libclang-dev \
        libc-dbg \
        libglib2.0-0 \
        libglib2.0-dev \
        libpcre3-dev \
        libxml2-dev \
        libssl-dev \
        openssl \
        make \
        netbase \
        python3 \
        python3-networkx \
        python3-jinja2 \
        python3-pyelftools \
        python3-pip \
        xz-utils \
        util-linux \
        gcc-14 \
        g++-14 \
        git \
        pkg-config \
        clang \
        patchelf \
        ninja-build \
        curl && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 && \
    rm -rf /var/lib/apt/lists/*

# Install latest Rust nightly via rustup
ENV RUSTUP_HOME=/usr/local/rustup \
	CARGO_HOME=/usr/local/cargo \
	PATH=/usr/local/cargo/bin:$PATH

RUN set -eux; \
	curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh; \
	sh /tmp/rustup-init.sh -y --default-toolchain nightly --profile minimal; \
	rm /tmp/rustup-init.sh; \
	rustc --version; cargo --version

# Ensure permissions for cargo/rustup dirs if later used by non-root
RUN chmod -R a+rX /usr/local/rustup /usr/local/cargo

# Shadow repository configuration
ARG SHADOW_REPO_URL="https://github.com/shadow/shadow.git"
ARG SHADOW_REF="main"

# Clone Shadow source
RUN set -eux; \
    mkdir -p /opt; cd /opt; \
    git clone "$SHADOW_REPO_URL" shadow-src; \
    cd shadow-src; git checkout "$SHADOW_REF"

# Build and install Shadow
RUN set -eux; \
	cd /opt/shadow-src; \
	./setup build --clean; \
	./setup install; \
	shadow --version || true; \
	cd /; \
	rm -rf /opt/shadow-src/.git; \
	rm -rf /opt/shadow-src/build 2>/dev/null || true

# Add shadow to PATH
ENV PATH="/root/.local/bin:$PATH"

