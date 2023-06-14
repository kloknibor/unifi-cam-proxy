ARG version=3.9
ARG tag=${version}-alpine3.17

<<<<<<< HEAD
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

=======
FROM python:${tag} as builder
WORKDIR /app
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN apk add --update \
        cargo \
        git \
        gcc \
        g++ \
        jpeg-dev \
        libc-dev \
        linux-headers \
        musl-dev \
        patchelf \
        rust \
        zlib-dev

RUN pip install -U pip wheel setuptools maturin
COPY requirements.txt .
RUN pip install -r requirements.txt --no-build-isolation


FROM python:${tag}
WORKDIR /app

ARG version

COPY --from=builder \
        /usr/local/lib/python${version}/site-packages \
        /usr/local/lib/python${version}/site-packages

RUN apk add --update ffmpeg netcat-openbsd libusb-dev

>>>>>>> parent of 47e3221 (Update Dockerfile)
COPY . .
RUN pip install . --no-cache-dir

COPY ./docker/entrypoint.sh /
<<<<<<< HEAD
=======

>>>>>>> parent of 47e3221 (Update Dockerfile)
ENTRYPOINT ["/entrypoint.sh"]
CMD ["unifi-cam-proxy"]
