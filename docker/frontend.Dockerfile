# Frontend: build the Vite app, then serve it with nginx.
# Build context is ./frontend (the submodule); nginx.conf comes from the "dockerfiles"
# build context (./docker), set in docker-compose.yml.
FROM node:22-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
# "/api" = same origin: nginx (below) proxies /api/* to the backend, so no CORS
# is needed. Set a full URL instead to call a backend hosted elsewhere.
ARG VITE_BACKEND_URL=/api
ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY --from=dockerfiles nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
