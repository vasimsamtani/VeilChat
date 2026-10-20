FROM node:20-alpine

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install production dependencies
RUN npm install --omit=dev

# Copy application source
COPY . .

# Ensure storage directories exist
RUN mkdir -p auth_info_baileys

EXPOSE 5055

ENV PORT=5055
ENV NODE_ENV=production

CMD ["node", "bridge.js"]
