FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (including devDependencies for build)
RUN npm install

# Copy the rest of the application
COPY . .

# Build the application
RUN npm run build

# Remove dev dependencies after build
RUN npm prune --production

EXPOSE 4321

# Use host 0.0.0.0 to allow external connections
CMD ["node", "./dist/server/entry.mjs"]