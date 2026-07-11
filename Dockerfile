# ==============================================================================
# Multi-stage Dockerfile for Fashion Brand Application
# This single Dockerfile supports building both frontend and backend target images.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. BACKEND STAGE (FastAPI built with uv)
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS backend

# Copy the uv binary from the official Astral uv image
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set environment variables to optimize Python/uv behavior in Docker
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV UV_COMPILE_BYTECODE=1

# Set the working directory
WORKDIR /app

# Install system dependencies (curl for healthchecks)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy pyproject.toml and uv.lock to leverage Docker layer caching
COPY pyproject.toml uv.lock ./

# Install dependencies using uv into the system Python
RUN uv pip install --system --no-cache -r pyproject.toml

# Copy all backend source code to the container
COPY Backend/ .

# Expose FastAPI default port
EXPOSE 8000

# Run FastAPI app with Uvicorn (production settings)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]


# ------------------------------------------------------------------------------
# 2. FRONTEND STAGE (Python HTTP Server)
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS frontend

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Copy all static assets (index.html, app.js, style.css) to the container
COPY Frontend/ .

# Expose Python HTTP server port
EXPOSE 3000

# Start python's built-in lightweight HTTP server to serve static assets
CMD ["python", "-m", "http.server", "3000"]