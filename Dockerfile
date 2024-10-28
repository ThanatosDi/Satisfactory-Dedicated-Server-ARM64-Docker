# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

ARG PUID=1000
ARG PGID=1000
ARG TZ=UTC

ENV TZ=${TZ}
ENV PUID=${PUID}
ENV PGID=${PGID}

# # Install cURL, Python 3, sudo, unbuffer and the package for "add-apt-repository"
# RUN apt update && apt install -y curl python3 sudo expect-dev software-properties-common

# # Fex build dependencies
# RUN apt install -y squashfs-tools squashfuse git python-setuptools pkgconf clang
# RUN apt install -y binfmt-support systemd cmake ninja-build software-properties-common
# RUN apt install -y libncurses6 libncurses5 libtinfo5 libtinfo6 libncurses-dev
# RUN apt install -y libsdl2-dev libepoxy-dev libssl-dev llvm lld

# Install cURL, Python 3, sudo, unbuffer and the package for "add-apt-repository" and Fex build dependencies
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
    binfmt-support \
    clang \
    cmake \
    curl \
    expect-dev \
    git \
    libepoxy-dev \
    libncurses-dev \
    libncurses5 \
    libncurses6 \
    libsdl2-dev \
    libssl-dev \
    libtinfo5 \
    libtinfo6 \
    lld \
    llvm \
    ninja-build \
    pkgconf \
    python-setuptools \
    python3 \
    qtbase5-dev \
    qtdeclarative5-dev \
    software-properties-common \
    software-properties-common \
    squashfs-tools \
    squashfuse \
    sudo \
    systemd \
    && rm -rf /var/lib/apt/lists/*

# compiling FEX
RUN add-apt-repository -y ppa:fex-emu/fex
RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git
WORKDIR FEX
RUN sed -i 's@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" FALSE@USE_LEGACY_BINFMTMISC "Uses legacy method of setting up binfmt_misc" TRUE@' ./CMakeLists.txt
RUN mkdir Build
WORKDIR Build
RUN CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja ..
RUN ninja &&\
    ninja install &&\
    ninja binfmt_misc &&\
    ninja binfmt_misc_64

# RUN ninja install
# RUN ninja binfmt_misc
# RUN ninja binfmt_misc_64

# Setting timezon
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime &&\
    echo ${TZ} > /etc/timezone

# Create user steam
RUN groupadd -g ${PGID} steam && \
    useradd -l -u ${PUID} -g steam -m steam

# RUN useradd -m steam

# InstallL FEX root FS
RUN sudo -u steam bash -c "unbuffer FEXRootFSFetcher -y -x"

# Change user to steam
USER steam

# Go to /home/steam/Steam
WORKDIR /home/steam/Steam

# Download and extract SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Copy init-server.sh to container
COPY --chmod=755 --chown=steam:steam ./init-server.sh /home/steam/init-server.sh
RUN chmod +x /home/steam/init-server.sh

# Run it
ENTRYPOINT /home/steam/init-server.sh
