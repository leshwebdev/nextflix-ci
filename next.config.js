/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  images: {
    unoptimized: true, // disable image optimization for static export
  },
  output: 'export', // optional for Next 13+
};

module.exports = nextConfig;
