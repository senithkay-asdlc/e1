FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm i
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
# The dataplane runs the container with a read-only root filesystem, so the
# rendered config can't be written back into /etc at startup. Keep the
# template outside conf.d and point nginx at a conf.d under /dev/shm instead
# (a tmpfs independent of the root fs), which the entrypoint script renders
# into at boot.
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/default.conf.template
COPY nginx/15-aep-api-proxy.sh /docker-entrypoint.d/15-aep-api-proxy.sh
RUN chmod +x /docker-entrypoint.d/15-aep-api-proxy.sh \
    && rm -f /etc/nginx/conf.d/default.conf
EXPOSE 9090
CMD ["nginx", "-g", "daemon off;"]
