# Stage 1: Build mdbook tools
FROM rust:latest AS builder

# Install mdbook and mdbook-mermaid using cargo
RUN cargo install mdbook mdbook-mermaid

# Stage 2: Final image with both scraper and mdbook
FROM python:3.12-slim

WORKDIR /workspace

# Install Python dependencies
COPY python/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy mdbook binaries from builder (cargo installs to /usr/local/cargo/bin)
COPY --from=builder /usr/local/cargo/bin/mdbook /usr/local/bin/
COPY --from=builder /usr/local/cargo/bin/mdbook-mermaid /usr/local/bin/

# Copy Python scripts
COPY python/deepwiki-scraper.py /usr/local/bin/deepwiki-scraper.py
COPY python/process-template.py /usr/local/bin/process-template.py
RUN chmod +x /usr/local/bin/deepwiki-scraper.py /usr/local/bin/process-template.py

# Copy default templates
COPY templates /workspace/templates

# Copy build script
COPY scripts/build-docs.sh /usr/local/bin/build-docs.sh
RUN chmod +x /usr/local/bin/build-docs.sh

# Default command builds everything
CMD ["/usr/local/bin/build-docs.sh"]
