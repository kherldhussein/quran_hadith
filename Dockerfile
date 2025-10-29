# syntax=docker/dockerfile:1.4

FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app

# Preload dependencies based on pubspec to leverage Docker layer caching
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the remainder of the source and build the Flutter web bundle
COPY . .
RUN flutter config --enable-web
RUN flutter pub get
RUN flutter build web --release

FROM nginx:1.27-alpine AS runtime
WORKDIR /usr/share/nginx/html

# Replace the default server configuration and publish the Flutter build
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web ./

EXPOSE 8080

CMD ["/docker-entrypoint.sh", "nginx", "-g", "daemon off;"]
