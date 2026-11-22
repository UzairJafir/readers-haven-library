# ============================================================
# Stage 1: Build the static site using Node.js
# ============================================================

# Use a pinned Node.js Alpine image as the build environment
FROM node:22-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy package manifest files first to leverage Docker layer caching
COPY package*.json ./

# Install dependencies cleanly using npm ci with network retries to prevent ECONNRESET drops
RUN npm config set fetch-retries 5 \
    && npm config set fetch-retry-mintimeout 20000 \
    && npm config set fetch-retry-maxtimeout 120000 \
    && (npm ci || npm ci || npm ci)

# Copy the source files needed for the build
COPY src/ ./src/

# Copy the style files needed for the build
COPY styles/ ./styles/

# Run the build script to generate production assets into /app/dist
RUN npm run build

# ============================================================
# Stage 2: Serve the built static files with Nginx
# ============================================================

# Use a pinned Nginx Alpine image as the lightweight production server
FROM nginx:1.27-alpine

# Copy the built static assets from the builder stage into Nginx's default serve directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80 for HTTP traffic
EXPOSE 80

# Start Nginx in the foreground so the container stays alive
CMD ["nginx", "-g", "daemon off;"]