FROM node:22-alpine AS deps
WORKDIR /app
# Manifests first so a source-only change reuses the dependency layer.
COPY package*.json ./
RUN npm ci

FROM node:22-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app ./
RUN npm ci --omit=dev
# Run unprivileged. `node` in this image is uid 1000; using the number so
# Kubernetes' runAsNonRoot check accepts it (a name it cannot verify).
USER 1000
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s \
  CMD node -e "fetch('http://127.0.0.1:3000/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "server.js"]
