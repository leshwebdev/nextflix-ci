FROM node:16-bullseye-slim AS runtime

WORKDIR /app

# Copy only dependency files first (better cache layer)
COPY package.json yarn.lock ./

# Install dependencies (runtime only)
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && yarn install --production --frozen-lockfile

# Copy the rest of the app
COPY . .

# Expose Next.js default port
EXPOSE 3000

# Run the exported static app with Next.js server
CMD ["yarn", "start"]
