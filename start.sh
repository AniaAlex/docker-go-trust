#!/usr/bin/env bash

# Start script for go-trust using config file
set -e

echo "Starting Go-Trust Service..."

# Essential environment variables (non-duplicated with config.yaml)
CONFIG_FILE=${CONFIG_FILE:-/etc/go-trust/config.yaml}
PIPELINE_FILE=${PIPELINE_FILE:-/app/pipeline.yaml}
NO_SERVER=${NO_SERVER:-false}

# Docker-specific overrides (to ensure proper container networking)
SERVICE_HOST=${SERVICE_HOST:-0.0.0.0}  # Ensure container accessibility

# Create config directory if it doesn't exist
CONFIG_DIR=$(dirname "${CONFIG_FILE}")
if [ ! -d "${CONFIG_DIR}" ]; then
   mkdir -p "${CONFIG_DIR}"
fi

echo "Configuration:"
echo "  Config File: ${CONFIG_FILE}"
echo "  Pipeline File: ${PIPELINE_FILE}"
echo "  No Server Mode: ${NO_SERVER}"
echo ""

# Build go-trust arguments
ARGS=""

# Add no-server flag for one-shot pipeline execution
if [ "${NO_SERVER}" = "true" ]; then
    ARGS="${ARGS} --no-server"
    echo "Running in one-shot mode (no API server)"
else
    # Ensure container accessibility by binding to all interfaces
    ARGS="${ARGS} --host ${SERVICE_HOST}"
    echo "Server will bind to: ${SERVICE_HOST}"
fi

# Add configuration file if it exists
if [ -f "${CONFIG_FILE}" ]; then
    ARGS="${ARGS} --config ${CONFIG_FILE}"
    echo "Using config: ${CONFIG_FILE}"
    echo "Server configuration will be read from config file"
else
    echo "Warning: Config file ${CONFIG_FILE} not found, using defaults"
fi

# Add pipeline file (required)
if [ -f "${PIPELINE_FILE}" ]; then
    ARGS="${ARGS} ${PIPELINE_FILE}"
    echo "Using pipeline: ${PIPELINE_FILE}"
else
    echo "Error: Pipeline file ${PIPELINE_FILE} not found"
    echo "The go-trust service requires a pipeline configuration file"
    exit 1
fi

echo "Starting gt with arguments: ${ARGS}"
echo "---"

# Execute gt binary
exec ./gt ${ARGS}
