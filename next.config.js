/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    unoptimized: true,        // DISABLE all Next.js image optimization
    loader: 'default',        // keep the default loader
    domains: [],              // allow no external domains
  },
  webpack: (config) => {
    config.resolve.fallback = { fs: false, path: false, os: false }; // fix WASM imports
    return config;
  },
};

module.exports = nextConfig;