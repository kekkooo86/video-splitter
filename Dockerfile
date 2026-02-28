# Video Splitter Docker Image
# Professional video splitting with labels and titles

FROM jrottenberg/ffmpeg:4.4-alpine

# Metadata labels
LABEL maintainer="xtxmotard@gmail.com"
LABEL version="1.4.1"
LABEL description="Video Splitter - Professional video segmentation with FFmpeg"
LABEL org.opencontainers.image.source="https://github.com/kekkooo86/video-splitter"
LABEL org.opencontainers.image.documentation="https://hub.docker.com/r/kekkooo86/video-splitter"

# Install only necessary dependencies for split_video.sh
RUN apk add --no-cache \
    bash \
    bc \
    sed \
    gawk \
    grep \
    coreutils \
    ttf-liberation \
    ttf-dejavu && \
    rm -rf /var/cache/apk/*

# Create working directory
WORKDIR /app

# Copy scripts (usa lo stesso script per locale e Docker!)
COPY split_video_core.sh /app/split_video_core.sh
COPY split_video.sh /app/split_video.sh
COPY README.md /app/

# Make scripts executable
RUN chmod +x /app/split_video_core.sh /app/split_video.sh

# Create empty fontconfig to avoid warnings
RUN mkdir -p /etc/fonts && \
    echo '<?xml version="1.0"?><!DOCTYPE fontconfig SYSTEM "fonts.dtd"><fontconfig></fontconfig>' > /etc/fonts/fonts.conf

# Environment variables to disable fontconfig warnings completely
ENV FONTCONFIG_FILE=/etc/fonts/fonts.conf
ENV FONTCONFIG_PATH=/etc/fonts
ENV DOCKER_CONTAINER=1

# Volume for videos
VOLUME ["/videos"]

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s \
  CMD ffmpeg -version > /dev/null || exit 1

# Simplified entrypoint
ENTRYPOINT ["/app/split_video.sh"]

# Default: show help
CMD ["-h"]


