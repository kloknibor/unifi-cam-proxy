# Set the base image and arguments
ARG version=3.9
ARG tag=${version}-bullseye

# Set up the environment
ENV CARGO_NET_GIT_FETCH_WITH_CLI=true

# Install necessary dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    libjpeg-dev \
    libffi-dev \
    libssl-dev \
    patchelf \
    rustc \
    cargo \
    zlib1g-dev \
    ffmpeg \
    netcat-openbsd \
    libusb-dev

# Set the working directory
WORKDIR /app

# Copy and install requirements
COPY requirements.txt .
RUN pip install -U pip wheel setuptools && \
    pip install -r requirements.txt --no-build-isolation

# Copy the application code
COPY . .

# Install the application
RUN pip install . --no-cache-dir

# Copy the entrypoint script
COPY ./docker/entrypoint.sh /

# Set the entrypoint command
ENTRYPOINT ["/entrypoint.sh"]

# Set the default command
CMD ["unifi-cam-proxy"]
