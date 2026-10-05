#!/bin/bash
set -e

# System update
sudo dnf update -y
sudo dnf install -y curl

# Install OpenTelemetry Collector
curl -Lo /tmp/otelcol.rpm https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.111.0/otelcol-contrib_0.111.0_linux_amd64.rpm
sudo dnf install -y /tmp/otelcol.rpm
rm -f /tmp/otelcol.rpm

# Configure and enable OTEL Collector
sudo mv /tmp/otel-config.yaml /etc/otelcol-contrib/config.yaml
sudo systemctl enable otelcol-contrib
sudo systemctl start otelcol-contrib