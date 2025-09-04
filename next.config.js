/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    unoptimized: true, // DISABLE image optimization
  },
};

module.exports = nextConfig;
