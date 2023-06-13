# Set the base image and arguments
ARG version=3.9
ARG tag=${version}-bullseye

# Stage 1: Builder
FROM python:${tag} as builder
WORKDIR /app
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libjpeg-dev \
    libffi-dev \
    libssl-dev \
    patchelf \
    rustc \
    cargo \
    zlib1g-dev

RUN pip install -U pip wheel setuptools maturin
COPY requirements.txt .
RUN pip install -r requirements.txt --no-build-isolation

# Stage 2: Final Image
FROM python:${tag}
WORKDIR /app

ARG version

COPY --from=builder \
    /usr/local/lib/python${version}/site-packages \
    /usr/local/lib/python${version}/site-packages

RUN apt-get update && apt-get install -y \
    ffmpeg \
    netcat-openbsd \
    libusb-dev

COPY . .
RUN pip install . --no-cache-dir

COPY ./docker/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["unifi-cam-proxy"]
