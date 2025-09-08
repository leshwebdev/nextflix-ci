# Use Node 18 Bullseye (full Debian, not Alpine)
FROM node:18-bullseye AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y \
    libc6-dev \
    libjpeg-dev \
    libpng-dev \
    && rm -rf /var/lib/apt/lists/*
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .
ENV NODE_OPTIONS="--openssl-legacy-provider"
RUN yarn build

# --- Optional: prepare minimal runtime image ---
FROM node:18-bullseye AS runtime
WORKDIR /app
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["yarn", "start"]
