FROM oven/bun:1 AS builder

WORKDIR /build

RUN apt-get update && apt-get install -y --no-install-recommends zip && rm -rf /var/lib/apt/lists/*

COPY . .

RUN bun install --frozen-lockfile

WORKDIR /build/apps/frontend

ENV VITE_BASE_URL=""
ENV VITE_NODE_ENV="production"

# Build the frontend
RUN bun run build

WORKDIR /build/apps/backend

# Build the backend
RUN bun build --compile --minify --sourcemap --target=bun-linux-x64 --outfile photosphere-server ./src/index.ts

# Have to use the Bun image so that we can install sharp.
FROM oven/bun:1

# Otherwise prefer to use this:
# FROM alpine:3

WORKDIR /app

COPY --from=builder /build/apps/frontend/dist ./public
COPY --from=builder /build/apps/backend/photosphere-server ./

# Have to add sharp otherwise it doesn't work.
RUN bun add sharp

ENV FRONTEND_STATIC_PATH=/app/public

CMD ./photosphere-server
# CMD sleep infinity
