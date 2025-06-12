#!/bin/bash

# Exit on error
set -e

# Script to run the workflow locally
# Usage: ./run_local.sh [additional snakemake options]

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."
for cmd in python3 R; do
    if ! command_exists "$cmd"; then
        echo "Error: $cmd is not installed or not in PATH"
        exit 1
    fi
done

# Check Python version
python_version=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
if [ "$(printf '%s\n' "3.9" "$python_version" | sort -V | head -n1)" != "3.9" ]; then
    echo "Error: Python 3.9 or higher is required"
    exit 1
fi

# Check R version
r_version=$(R --version | head -n1 | grep -oP '\d+\.\d+')
if [ "$(printf '%s\n' "4.0" "$r_version" | sort -V | head -n1)" != "4.0" ]; then
    echo "Error: R 4.0 or higher is required"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "env" ]; then
    echo "Creating virtual environment..."
    python3 -m venv env
fi

# Install/update required Python packages
echo "Installing/updating required Python packages..."
pip install --upgrade pip
pip install -r requirements.txt

# Install required R packages
echo "Installing/updating required R packages..."
Rscript requirements.R

# Check if config file exists
if [ ! -f "workflow/config.yaml" ]; then
    echo "Error: workflow/config.yaml not found"
    echo "Please create the config file following the template in README.md"
    exit 1
fi

# Create necessary directories
echo "Creating directory structure..."
mkdir -p logs/{initial_qc,variant_qc,sample_qc,final_qc} \
         results/{initial_qc,variant_qc,sample_qc,final_qc}

# Run snakemake
echo "Running workflow..."
snakemake --profile profiles/local "$@" 