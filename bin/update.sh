#!/bin/bash -x

# Move to a known location and save as START_DIR.
cd "$(dirname "$(dirname "${0}")")" || exit 1
START_DIR="${PWD}"

# Ensure we exit if anything usingn a pipe ('|') fails.
set -e -o pipefail

# Get the latest tag from the GitHub API.
HOME_ASSISTANT_CORE_LATEST_TAG="$(curl -Ls https://api.github.com/repos/home-assistant/core/tags | jq '.[].name' | sed 's/"//g' | grep -Ev '[[:alpha:]]' | sort -V | tail -n 1)"
if [[ -n "${GITHUB_ENV}" ]]; then
  echo "latest_tag=${HOME_ASSISTANT_CORE_LATEST_TAG}" >>"$GITHUB_ENV"
fi

# If we haven't already checked out the repo, do so now.
if [[ ! -d upstream ]]; then

  # Clone the repo max-depth of 1 commit as we only need the latest.
  git clone --depth 1 https://github.com/home-assistant/core/ upstream

  # Ensure that the core directory gets cleaned up on exit.
  trap "rm -rf "${START_DIR}/upstream"" EXIT

fi

# Create a variable for the source directory we are using.
SRC_DIR="${START_DIR}/upstream/homeassistant/components/default_config"

# Check the source directory exists
test -d "${SRC_DIR}" || exit 1

# Create somewhere for our updated code to go.
if [[ ! -d custom_components/default_config ]]; then
  mkdir -p custom_components/default_config
fi

# Check for changed files
if [[ $(rsync -avz --checksum --dry-run ${START_DIR}/upstream/homeassistant/components/default_config ${START_DIR}/custom_components | grep -c default_config) -gt 1 ]]; then

  # Copy over the upstream files
  rsync -avz "${START_DIR}/upstream/homeassistant/components/default_config" "${START_DIR}/custom_components"

  # Add in required data for the component to get loaded
  cat <<<$(jq ". + { "version": \"${HOME_ASSISTANT_CORE_LATEST_TAG}.1\" }" ${START_DIR}/custom_components/default_config/manifest.json) >${START_DIR}/custom_components/default_config/manifest.json

  # Disable the 'cloud' integration.
  cat <<<$(jq 'del(.dependencies[] | select(. == "cloud"))' ${START_DIR}/custom_components/default_config/manifest.json) >${START_DIR}/custom_components/default_config/manifest.json

  # Update hacs.json with the minimum homeassistant value for the latest release
  cat <<<$(jq ".homeassistant = \"${HOME_ASSISTANT_CORE_LATEST_TAG}\"" ${START_DIR}/hacs.json) >${START_DIR}/hacs.json

fi
