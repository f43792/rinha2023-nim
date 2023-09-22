# Use the official Nim image from Docker Hub (2.0.0)
FROM nimlang/nim:2.0.0 AS build-env

# Install PostgreSQL client library
RUN apt-get update && apt-get install -y libpq-dev

# Set the working directory
WORKDIR /app

# Copy nimble setup files
COPY rinha2023_nim.nimble rinha2023_nim.nimble

# Install dependencies
RUN nimble install -y -d

# Copy the current directory contents into the container
COPY . .

# Compile the Nim application using switches from rinha.nims
RUN nim c src/rinha.nim

EXPOSE 3000:3000

# Run the compiled Nim application
CMD ["sh", "-c", "/app/rinha_nim"]
