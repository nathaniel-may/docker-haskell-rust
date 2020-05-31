FROM haskell:8.8.3

WORKDIR /usr/app

# rust env vars
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.43.0

# install stuff to install stuff
RUN apt-get update \
  && apt-get install -y \
    wget \
    software-properties-common \
    apt-transport-https \
    ca-certificates

# install clang
RUN wget https://apt.llvm.org/llvm.sh &&\
  chmod +x llvm.sh &&\
  ./llvm.sh 11

# script taken from rust docker image
RUN set -eux; \
    dpkgArch="$(dpkg --print-architecture)"; \
    case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu'; rustupSha256='ad1f8b5199b3b9e231472ed7aa08d2e5d1d539198a15c5b1e53c746aad81d27b' ;; \
        armhf) rustArch='armv7-unknown-linux-gnueabihf'; rustupSha256='6c6c3789dabf12171c7f500e06d21d8004b5318a5083df8b0b02c0e5ef1d017b' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu'; rustupSha256='26942c80234bac34b3c1352abbd9187d3e23b43dae3cf56a9f9c1ea8ee53076d' ;; \
        i386) rustArch='i686-unknown-linux-gnu'; rustupSha256='27ae12bc294a34e566579deba3e066245d09b8871dc021ef45fc715dced05297' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.21.1/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION; \
    rm rustup-init; \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME; \
    rustup --version; \
    cargo --version; \
    rustc --version;

# -- cache compiled rust libraries in docker image --
#                  -- HOT MESS --
# create the directory where circleci checks out code
# it will get overwritten but this just simulates the 
# install of dependencies so that they can be cached
# in the docker image. It's ugly I know, but CircleCI 
# kills the build process so here we are.
# 
# [EDIT]: I haven't verified it yet but I think it's 
# because CircleCI has a default to terminate if 
# theres no output for 10 mins for any process.
RUN mkdir -p /root/project/rust/src\
  && cd /root/project/rust\
  && echo '[package]\nname = "beep"\nversion = "0.1.0"\nedition = "2018"\n[dependencies]\nanyhow = "1.0"\nbytes = "0.5"\nfutures = "0.3"\nrocksdb = "0.14"\nserde = { version = "1.0", features = ["derive"] }\nserde_cbor = "0.11"\ntake_mut = "0.2"\ntokio = { version = "0.2", features = ["tcp", "rt-threaded", "stream"] }\ntokio-util = { version = "0.3", features = ["codec"] }' > Cargo.toml\
  && echo 'fn main() { println!("Hello World!"); }' > src/main.rs\
  && cargo build
