# ====== etap build ======
FROM node:20-alpine AS build
WORKDIR /app

# kopiowanie zależności
COPY package*.json ./
RUN npm install

# kopiowanie kodu
COPY . .

# build aplikacji
RUN npm run build

# ====== etap runtime ======
FROM nginx:alpine

# usuń domyślną konfigurację nginx
RUN rm -f /etc/nginx/conf.d/default.conf

# skopiuj gotowy plik nginx.conf z repo (jeśli jest dostosowany)
COPY nginx.conf /etc/nginx/conf.d/app.conf

# skopiuj statyczne pliki z builda
COPY --from=build /app/dist /usr/share/nginx/html

# expose port 80 (zgodnie z docker-compose)
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
