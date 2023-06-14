ARG version=3.9
ARG tag=${version}-alpine3.17

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

RUN apk add --update ffmpeg netcat-openbsd libusb-dev

# Install VAAPI dependencies for Intel Gen 8+
RUN apk add --no-cache --virtual .build-deps \
        build-base \
        libpciaccess-dev \
        libdrm-dev \
        autoconf \
        automake \
        libtool \
        linux-headers \
        libx11-dev \
        libva-dev \
        mesa-dev

# Download and install Intel Media Driver
RUN git clone https://github.com/intel/media-driver.git \
        && cd media-driver \
        && git checkout -b release/intel-media-21.3.4 origin/release/intel-media-21.3.4 \
        && mkdir -p build && cd build \
        && cmake -DCMAKE_INSTALL_PREFIX=/usr -DBUILD_TYPE=release -DMEDIA_VERSION="21.3.4" .. \
        && make -j$(nproc) \
        && make install

# Download and install LibVA
RUN git clone https://github.com/intel/libva.git \
        && cd libva \
        && git checkout -b intel-media-21.3.4 origin/intel-media-21.3.4 \
        && ./autogen.sh --prefix=/usr --libdir=/usr/lib64 \
        && make -j$(nproc) \
        && make install

COPY --from=builder \
        /usr/local/lib/python${version}/site-packages \
        /usr/local/lib/python${version}/site-packages

COPY . .
RUN pip install . --no-cache-dir

COPY ./docker/entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["unifi-cam-proxy"]
