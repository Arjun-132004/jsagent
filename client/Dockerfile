FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi
COPY . .
RUN npm run build

# Unprivileged nginx: uid 101, listens on 8080, writable paths under /tmp.
# Stock nginx here would need root for :80 and /var/cache/nginx and exits
# [emerg] under the manifest's runAsNonRoot + readOnlyRootFilesystem.
FROM nginxinc/nginx-unprivileged:1.27-alpine
# The SPA's nginx config — WITHOUT this the image keeps nginx's stock
# default.conf, which has no `try_files ... /index.html`. The site then
# loads at / and 404s on every client-side route: /dashboard, /login, and
# any refresh away from the root (2026-09, javacheck). deploy_my_app commits
# nginx.conf beside this Dockerfile whenever it writes one, so the two
# always travel together.
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Build output: Vite writes to dist/ (vite.config.js).
COPY --from=build /app/dist /usr/share/nginx/html
# Already the image's default; stated so the manifest's runAsUser has
# something to agree with and the review rules can see it.
USER 101
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
