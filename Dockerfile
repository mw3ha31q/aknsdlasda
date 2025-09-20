# syntax=docker/dockerfile:1.6

FROM node:20-alpine

# Optional: tools for native builds (remove if not needed)
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Turn on verbose npm logging and sane network retries
ENV NPM_CONFIG_LOGLEVEL=verbose \
    NPM_CONFIG_PROGRESS=false \
    NPM_CONFIG_FOREGROUND_SCRIPTS=true \
    NPM_CONFIG_UPDATE_NOTIFIER=false \
    NPM_CONFIG_FETCH_RETRIES=5 \
    NPM_CONFIG_FETCH_RETRY_MINTIMEOUT=20000 \
    NPM_CONFIG_FETCH_RETRY_MAXTIMEOUT=120000 \
    # sometimes helpful if private registries are slow:
    NPM_CONFIG_TIMING=true

# Show versions up front in the logs
RUN node -v && npm -v

COPY package*.json ./

# Use BuildKit cache and crank up verbosity
# Falls back to `npm install` if there’s no lockfile
RUN --mount=type=cache,target=/root/.npm \
    if [ -f package-lock.json ]; then \
      npm ci --verbose --no-audit --no-fund; \
    else \
      npm install --verbose --no-audit --no-fund; \
    fi

COPY . .

RUN npm run build

EXPOSE 4321

CMD ["npm", "run", "preview", "--", "--host", "0.0.0.0", "--port", "4321"]
