# Frontend: build the Vite app, then serve it with nginx.
# Build context is the monorepo root (works with Docker Compose and Render).
FROM node:22-alpine AS build
WORKDIR /app

COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ .
# "/api" = same origin: nginx (below) proxies /api/* to the backend, so no CORS
# is needed. Set a full URL instead to call a backend directly.
ARG VITE_BACKEND_URL=/api
ENV VITE_BACKEND_URL=${VITE_BACKEND_URL}
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
# The nginx image fills in ${BACKEND_UPSTREAM} from the environment at startup.
COPY docker/nginx.conf.template /etc/nginx/templates/default.conf.template
ENV BACKEND_UPSTREAM=http://backend:8000
EXPOSE 80
