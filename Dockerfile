# use a lightweight Node.js image

FROM node:18-alpine

# set working directory
WORKDIR /app

# Copy package files first and install dependanceies
COPY package*.json ./
RUN npm install

# Copy the rest of the code
COPY . .

# expose port 3700
EXPOSE 3700

# start app
CMD ["node", "index.js"]