# Set the base image and arguments
ARG version=3.9
ARG tag=${version}-bullseye

# Stage 1: Builder Dependencies
FROM python:${tag} as builder-dependencies-amd64
WORKDIR /app
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libjpeg-dev \
    libffi-dev \
    libssl-dev \
    patchelf \
    zlib1g-dev

# Install a newer version of Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN pip install -U pip wheel setuptools maturin

# Stage 2: Builder Application (AMD64)
FROM builder-dependencies-amd64 as builder-application-amd64
COPY requirements.txt .
RUN pip install -r requirements.txt --no-build-isolation

# Stage 3: Final Image (AMD64)
FROM python:${tag} as final-amd64
WORKDIR /app

RUN apt-get update && apt-get install -y \
    ffmpeg \
    netcat-openbsd \
    libusb-dev

COPY --from=builder-application-amd64 /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

COPY . .
RUN pip install . --no-cache-dir

COPY ./docker/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["unifi-cam-proxy"]

# Stage 4: Builder Dependencies (ARM)
FROM --platform=linux/arm/v7 python:${tag} as builder-dependencies-arm
RUN apt-get update && apt-get install -y curl

# Stage 5: Builder Application (ARM)
FROM --platform=linux/arm/v7 builder-dependencies-arm as builder-application-arm
COPY requirements.txt .
RUN pip install -r requirements.txt --no-build-isolation

# Stage 6: Final Image (ARM)
FROM --platform=linux/arm/v7 python:${tag} as final-arm
WORKDIR /app

RUN apt-get update && apt-get install -y \
    ffmpeg \
    netcat-openbsd \
    libusb-dev

COPY --from=builder-application-arm /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

COPY . .
RUN pip install . --no-cache-dir

COPY ./docker/entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["unifi-cam-proxy"]
