/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,   // keep strict mode enabled
  images: {
    unoptimized: true,     // disable built-in image optimization to fix .wasm build error
  },
};

module.exports = nextConfig;
