# Official Debian Wine/QEMU tools only. No Steam/game DLL replacements.
FROM debian:trixie-slim
RUN --mount=type=secret,id=proxy_ca,required=true \
    dpkg --add-architecture i386 && \
    apt-get -o Acquire::https::CaInfo=/run/secrets/proxy_ca update && \
    DEBIAN_FRONTEND=noninteractive apt-get -o Acquire::https::CaInfo=/run/secrets/proxy_ca install -y --no-install-recommends \
      wine wine32:i386 wine64 wine32-preloader:i386 wine64-preloader qemu-user \
      xvfb xauth xdotool x11-utils scrot python3 python3-pil libgl1-mesa-dri fonts-dejavu-core && \
    rm -rf /var/lib/apt/lists/*
ENV DISPLAY=:99 WINEDEBUG=-all
