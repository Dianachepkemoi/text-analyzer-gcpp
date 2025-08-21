# Use a small, verified image
FROM python:3.12-slim

# Create a non-root user
RUN useradd -m appuser

# Set workdir
WORKDIR /app

# Install security updates and runtime deps
RUN apt-get update && apt-get install -y --no-install-recommends     ca-certificates  && rm -rf /var/lib/apt/lists/*

# Copy dependency manifests first for better layer caching
COPY requirements.txt ./

# Install Python deps
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ ./app/

# Change ownership and switch to non-root
RUN chown -R appuser:appuser /app
USER appuser

# Expose the port Cloud Run expects
EXPOSE 8080

# Run the app with Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
