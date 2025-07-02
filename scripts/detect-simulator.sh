#!/bin/bash

# Simulator Detection Script for CI/CD environments
# Supports CircleCI, GitHub Actions, and local development

set -euo pipefail

# Default values
DEFAULT_DEVICE="iPhone 15"
DEFAULT_OS="18.5"
DEFAULT_PLATFORM="iOS Simulator"

# Device priority list (fallback order)
DEVICE_PRIORITY=(
    "iPhone 15"
    "iPhone 14"
    "iPhone 13"
    "iPhone 12"
    "iPhone SE (3rd generation)"
)

# iOS version priority list (fallback order)
IOS_VERSION_PRIORITY=(
    "18.5"
    "18.4"
    "18.3"
    "18.2"
    "18.1"
    "18.0"
    "17.5"
    "17.4"
)

# Function to detect CI environment
detect_ci_environment() {
    if [[ "${CI:-}" == "true" && "${CIRCLECI:-}" == "true" ]]; then
        echo "circleci"
    elif [[ "${CI:-}" == "true" && "${GITHUB_ACTIONS:-}" == "true" ]]; then
        echo "github_actions"
    else
        echo "local"
    fi
}

# Function to get available simulators
get_available_simulators() {
    # Use simpler approach without jq dependency
    xcrun simctl list devices available | grep -E "iPhone" | grep -v "unavailable" | sed 's/^[[:space:]]*//'
}

# Function to find best matching simulator
find_best_simulator() {
    local available_simulators="$1"
    local environment="$2"
    
    # Extract iOS versions from simulator list headers and use priority list
    local available_ios_versions=$(xcrun simctl list devices available | rg -- "-- iOS" | sed -E 's/^-- iOS ([0-9]+\.[0-9]+) --.*/\1/')
    
    # Try each device in priority order
    for device in "${DEVICE_PRIORITY[@]}"; do
        if echo "$available_simulators" | grep -qi "$device"; then
            # Try each iOS version in priority order for this device
            for ios_version in "${IOS_VERSION_PRIORITY[@]}"; do
                if echo "$available_ios_versions" | grep -q "^${ios_version}$"; then
                    echo "${device}|${ios_version}"
                    return 0
                fi
            done
            # If no priority version found, use the first available version
            local first_version=$(echo "$available_ios_versions" | head -1)
            if [[ -n "$first_version" ]]; then
                echo "${device}|${first_version}"
                return 0
            fi
        fi
    done
    
    # If no priority device found, use first available iPhone
    local first_iphone=$(echo "$available_simulators" | head -1)
    if [[ -n "$first_iphone" ]]; then
        # Extract device name (remove UUID and status)
        local device_name=$(echo "$first_iphone" | sed -E 's/^([^(]+) \([^)]+\) \([^)]+\).*/\1/' | xargs)
        # Get the first available iOS version
        local ios_version=$(echo "$available_ios_versions" | head -1)
        echo "${device_name}|${ios_version}"
        return 0
    fi
    
    # Ultimate fallback
    echo "${DEFAULT_DEVICE}|${DEFAULT_OS}"
}

# Function to log environment info
log_environment_info() {
    local environment="$1"
    local device="$2"
    local ios_version="$3"
    
    echo "=== Simulator Detection Report ===" >&2
    echo "Environment: $environment" >&2
    echo "Selected Device: $device" >&2
    echo "Selected iOS Version: $ios_version" >&2
    echo "Platform: $DEFAULT_PLATFORM" >&2
    
    if [[ "$environment" == "circleci" ]]; then
        echo "CircleCI Xcode Version: ${XCODE_VERSION:-'Unknown'}" >&2
    elif [[ "$environment" == "github_actions" ]]; then
        echo "GitHub Actions Runner: ${RUNNER_OS:-'Unknown'}" >&2
        echo "Developer Dir: ${DEVELOPER_DIR:-'Default'}" >&2
    fi
    echo "=================================" >&2
}

# Main execution
main() {
    # Allow environment variable overrides
    local target_device="${TEST_DEVICE:-}"
    local target_os="${TEST_OS:-}"
    
    # If both are manually set, use them
    if [[ -n "$target_device" && -n "$target_os" ]]; then
        echo "platform=${DEFAULT_PLATFORM},name=${target_device},OS=${target_os}"
        return 0
    fi
    
    # Detect environment
    local environment=$(detect_ci_environment)
    
    # Get available simulators
    local available_simulators=$(get_available_simulators)
    
    # Find best simulator if not manually specified
    if [[ -z "$target_device" || -z "$target_os" ]]; then
        local best_match=$(find_best_simulator "$available_simulators" "$environment")
        local detected_device=$(echo "$best_match" | cut -d'|' -f1)
        local detected_os=$(echo "$best_match" | cut -d'|' -f2)
        
        # Use detected values if not manually set
        target_device="${target_device:-$detected_device}"
        target_os="${target_os:-$detected_os}"
    fi
    
    # Log the selection
    log_environment_info "$environment" "$target_device" "$target_os"
    
    # Output the destination string
    echo "platform=${DEFAULT_PLATFORM},name=${target_device},OS=${target_os}"
}

# Execute main function
main "$@"