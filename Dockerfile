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

# Runtime stage: run backend with Bun (no compile)
FROM oven/bun:1

WORKDIR /app

# Monorepo layout so workspace deps resolve; sharp and other natives come from builder (linux-x64)
COPY --from=builder /build/package.json /build/bun.lock ./
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/apps/backend ./apps/backend
COPY --from=builder /build/packages ./packages
COPY --from=builder /build/apps/frontend/dist ./public

ENV FRONTEND_STATIC_PATH=/app/public

CMD ["bun", "run", "apps/backend/src/index.ts"]
