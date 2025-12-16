# ====== build stage (Debian, stabilniej niż Alpine) ======
FROM node:20-bookworm-slim AS build
WORKDIR /app

# Kopiuj manifesty zależności
COPY package.json ./
# jeśli kiedyś dodasz lockfile, też zostanie użyty
COPY package-lock.json* ./

# Ustawienia npm: mniej "hałasu" i więcej retry przy problemach z siecią
RUN npm config set fund false \
 && npm config set audit false \
 && npm config set fetch-retries 5 \
 && npm config set fetch-retry-mintimeout 20000 \
 && npm config set fetch-retry-maxtimeout 120000

# Instalacja zależności
RUN npm install --no-audit --no-fund

# Kod aplikacji + build
COPY . .
RUN npm run build


# ====== runtime stage ======
FROM nginx:alpine

# Konfiguracja nginx dla SPA (React): gdy nie ma pliku, zwróć index.html
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

# Skopiuj wynik buildu Vite
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
