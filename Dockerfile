# ====== build stage ======
FROM node:20-bookworm-slim AS build
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

# Szybka diagnostyka sieci/DNS/SSL (to bardzo często jest powód w Portainerze)
RUN set -eux; \
    node -v; npm -v; \
    echo "== DNS test =="; \
    getent hosts registry.npmjs.org || true; \
    echo "== HTTPS test =="; \
    curl -I https://registry.npmjs.org/ || true; \
    echo "== NPM ping =="; \
    npm ping --registry=https://registry.npmjs.org/ || true

COPY package.json ./
COPY package-lock.json* ./

# Wypisz błąd npm wprost do logu (verbose) + obejście peer deps
RUN set -eux; \
    npm config set audit false; \
    npm config set fund false; \
    npm config set registry https://registry.npmjs.org/; \
    npm install --no-audit --no-fund --legacy-peer-deps --loglevel verbose

COPY . .
RUN npm run build


# ====== runtime stage ======
FROM nginx:alpine

RUN rm -f /etc/nginx/conf.d/default.conf && \
    printf '%s\n' \
'server {' \
'  listen 80;' \
'  server_name _;' \
'  root /usr/share/nginx/html;' \
'  index index.html;' \
'  location / { try_files $uri $uri/ /index.html; }' \
'}' \
> /etc/nginx/conf.d/app.conf

COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
