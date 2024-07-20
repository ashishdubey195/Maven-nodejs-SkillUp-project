# Use the official Node.js image from the Docker Hub
FROM node:latest

# Set the working directory inside the container
WORKDIR /apps

# Copy the application files to the container
ADD . .

# Install Node.js dependencies
RUN npm install

# Expose the port the app runs on
EXPOSE 3000

# Command to run the app
CMD ["node", "index.js"]
