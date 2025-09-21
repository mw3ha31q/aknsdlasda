FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with better error handling
RUN npm ci --only=production || npm install --only=production

# Copy the rest of the application
COPY . .

# Build the application
RUN npm run build

EXPOSE 4321

# Use host 0.0.0.0 to allow external connections
CMD ["node", "./dist/server/entry.mjs"]
