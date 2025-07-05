# MLOps Platform Demo - Multi-stage Dockerfile
# Optimized for production deployment with security best practices

# Stage 1: Build stage with full dependencies
FROM python:3.9-slim as builder

# Set build arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=1.0.0

# Add metadata
LABEL org.opencontainers.image.title="MLOps Platform Demo" \
    org.opencontainers.image.description="LUCID Therapeutics Music Therapy ML Platform" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.created=$BUILD_DATE \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.vendor="LUCID Therapeutics" \
    org.opencontainers.image.source="https://github.com/lucid/mlops-platform-demo"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY pipeline/requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Stage 2: Production stage
FROM python:3.9-slim as production

# Create non-root user for security
RUN groupadd -r mlops && useradd -r -g mlops mlops

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy installed packages from builder stage
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY pipeline/ ./pipeline/
COPY model-deploy/ ./model-deploy/
COPY mlflow/ ./mlflow/

# Create necessary directories
RUN mkdir -p /app/data /app/models /app/logs && \
    chown -R mlops:mlops /app

# Switch to non-root user
USER mlops

# Set environment variables
ENV PYTHONPATH=/app \
    PYTHONUNBUFFERED=1 \
    MLFLOW_TRACKING_URI=http://mlflow-service.mlflow:5000 \
    MODEL_NAME=music-therapy-classifier \
    LOG_LEVEL=INFO

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import sys; sys.exit(0)" || exit 1

# Expose port for model serving
EXPOSE 8080

# Default command - can be overridden
CMD ["python", "pipeline/simple_pipeline.py", "--run"]

# Alternative commands for different use cases:
# docker run <image> python pipeline/simple_pipeline.py --demo
# docker run <image> python pipeline/pipeline.py --run (if dependencies available)
# docker run <image> mlflow server --host 0.0.0.0 --port 5000
