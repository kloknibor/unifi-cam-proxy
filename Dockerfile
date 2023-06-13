ARG version=3.9
ARG tag=${version}-bullseye

FROM python:${tag} as builder
WORKDIR /app
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

# Add non-free repositories
RUN echo "deb http://deb.debian.org/debian/ sid non-free" >> /etc/apt/sources.list \
    && echo "deb-src http://deb.debian.org/debian/ sid non-free" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        gcc \
        g++ \
        libjpeg-dev \
        libc-dev \
        musl-dev \
        patchelf \
        zlib1g-dev \
        curl
        
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# Update package lists and remove intel-media-va-driver
RUN apt-get remove -y intel-media-va-driver

# Install i965-va-driver-shaders
RUN apt-get install -y i965-va-driver-shaders

RUN pip install -U pip wheel setuptools maturin
COPY requirements.txt .
RUN pip install -r requirements.txt --no-build-isolation


FROM python:${tag}
WORKDIR /app

ARG version

COPY --from=builder \
        /usr/local/lib/python${version}/site-packages \
        /usr/local/lib/python${version}/site-packages

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    netcat-openbsd \
    libusb-dev

COPY . .
RUN pip install . --no-cache-dir

COPY ./docker/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["unifi-cam-proxy"]
