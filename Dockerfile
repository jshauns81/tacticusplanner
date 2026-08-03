FROM node:22-bookworm-slim AS build

WORKDIR /app

# node-canvas / sharp / svgo fall back to a source build when no prebuilt binary
# matches, so keep the toolchain and cairo headers available.
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 make g++ pkg-config \
        libcairo2-dev libpango1.0-dev libjpeg-dev libgif-dev librsvg2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json .npmrc ./
COPY patches ./patches
RUN npm ci

COPY . .

# `build` reads environments/.env.production -> upstream Azure Functions backend
ARG BUILD_MODE=build
RUN npm run ${BUILD_MODE}

FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
