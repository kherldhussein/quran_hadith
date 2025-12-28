# syntax=docker/dockerfile:1.4

# Build stage - Flutter web compilation
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

ARG FLUTTER_BUILD_MODE=release

# Preload dependencies based on pubspec to leverage Docker layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the remainder of the source and build the Flutter web bundle
COPY . .
RUN flutter config --enable-web && \
    flutter build web --${FLUTTER_BUILD_MODE}

# Runtime stage - Nginx serving with multi-arch support
FROM cgr.dev/chainguard/nginx:latest AS runtime
WORKDIR /usr/share/nginx/html

# Replace the default server configuration and publish the Flutter build
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web ./

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/ || exit 1

EXPOSE 8080

# Labels for metadata
LABEL org.opencontainers.image.title="Quran & Hadith Web" \
      org.opencontainers.image.description="Quran and Hadith web application built with Flutter" \
      org.opencontainers.image.source="https://github.com/kherldhussein/quran_hadith" \
      org.opencontainers.image.licenses="MIT"

CMD ["nginx", "-g", "daemon off;"]
