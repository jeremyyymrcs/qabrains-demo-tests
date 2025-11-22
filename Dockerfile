# Builder stage: Install dependencies, Python packages, Allure, and Playwright browsers
FROM python:3.12-slim-bullseye AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build tools and system dependencies needed for installing packages and Playwright
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
        libxkbcommon0 libxcomposite1 libxrandr2 libgbm1 libasound2 \
        libpangocairo-1.0-0 libxshmfence1 libxdamage1 libxfixes3 \
        libx11-xcb1 libxss1 ca-certificates wget unzip \
        openjdk-11-jre-headless curl tar \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only requirements.txt for dependency installation
COPY requirements.txt /app/

# Install Python dependencies and Playwright
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir playwright

# Install Allure
RUN curl -L https://repo.maven.apache.org/maven2/io/qameta/allure/allure-commandline/2.33.0/allure-commandline-2.33.0.tgz \
    | tar -xz -C /opt \
    && mv /opt/allure-2.33.0 /opt/allure \
    && rm -rf /opt/allure/docs /opt/allure/examples


# Create non-root user and install Chromium (browsers are cached in user's home)
RUN useradd -m pwuser
USER pwuser
RUN playwright install chromium \
    && rm -rf /home/pwuser/.cache/ms-playwright/*/{.local-browsers,debug.log}

# Final stage: Minimal runtime image
FROM python:3.12-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime system dependencies (no build tools or installers)
RUN apt-get update && apt-get install -y --no-install-recommends \
        libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
        libxkbcommon0 libxcomposite1 libxrandr2 libgbm1 libasound2 \
        libpangocairo-1.0-0 libxshmfence1 libxdamage1 libxfixes3 \
        libx11-xcb1 libxss1 ca-certificates \
        openjdk-11-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python packages from builder
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy Allure from builder and create symlink
COPY --from=builder /opt/allure /opt/allure
RUN ln -s /opt/allure/bin/allure /usr/local/bin/allure

# Create non-root user
RUN useradd -m pwuser

# Copy Playwright browser cache from builder (owned by pwuser)
COPY --from=builder --chown=pwuser:pwuser /home/pwuser/.cache /home/pwuser/.cache

# Copy application code and fix scripts
COPY --chown=pwuser:pwuser . /app
RUN find /app/tests/docker -type f -name "*.sh" -exec sed -i 's/\r//' {} \; \
    && find /app/tests/docker -type f -name "*.sh" -exec chmod +x {} \;

USER pwuser
WORKDIR /app/tests/docker

CMD ["bash", "-c", "./run_all_test_suites.sh -async"]
