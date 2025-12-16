# ====== build stage ======
FROM node:20-bookworm-slim AS build
WORKDIR /app

# Narzędzia, które często są potrzebne przy instalacji paczek:
# - ca-certificates: SSL do registry
# - git: gdy zależność jest z repo
# - python3/make/g++: gdy jakaś paczka buduje bindingi
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

# Lepsze zachowanie npm w środowiskach typu Portainer (mniej problemów z siecią)
RUN npm config set fund false \
 && npm config set audit false \
 && npm config set fetch-retries 5 \
 && npm config set fetch-retry-mintimeout 20000 \
 && npm config set fetch-retry-maxtimeout 120000

# Manifesty zależności
COPY package.json ./
COPY package-lock.json* ./

# Instalacja zależności + DIAGNOSTYKA:
# - --legacy-peer-deps: omija częsty błąd ERESOLVE
# - w razie błędu wypisuje logi z /root/.npm/_logs
RUN npm install --no-audit --no-fund --legacy-peer-deps \
 || (echo "===== NPM LOGS =====" && ls -la /root/.npm/_logs && tail -n +1 /root/.npm/_logs/* && exit 1)

# Kod + build
COPY . .
RUN npm run build


# ====== runtime stage ======
FROM nginx:alpine

RUN rm -f /etc/nginx/conf.d/default.conf && \
    printf '%s\n' \
'server {' \
'  listen 80;' \
'  server_name _;' \
'' \
'  root /usr/share/nginx/html;' \
'  index index.html;' \
'' \
'  location / {' \
'    try_files $uri $uri/ /index.html;' \
'  }' \
'}' \
> /etc/nginx/conf.d/app.conf

COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
