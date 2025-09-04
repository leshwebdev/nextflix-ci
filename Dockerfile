# Stage 1: Build the Next.js app
FROM node:18-bullseye AS builder
WORKDIR /app
COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile
COPY . .

ENV NODE_OPTIONS="--openssl-legacy-provider"
RUN yarn build && yarn export

# Stage 2: Serve with a lightweight web server
FROM nginx:alpine
COPY --from=builder /app/out /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
