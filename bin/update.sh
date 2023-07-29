#!/bin/bash -x

# Move to a known location and save as START_DIR.
cd "$(dirname "$(dirname "${0}")")" || exit 1
START_DIR="${PWD}"

# Ensure we exit if anything usingn a pipe ('|') fails.
set -e -o pipefail

# If we haven't already checked out the repo, do so now.
if [[ ! -d core ]]; then

  # Clone the repo max-depth of 1 commit as we only need the latest.
  git clone --depth 1 --recursive https://github.com/home-assistant/core/

fi

# Ensure that the core directory gets cleaned up on exit.
trap "rm -rf "${START_DIR}/core"" EXIT

# Create a variable for the source directory we are using.
SRC_DIR="${START_DIR}/core/homeassistant/components/default_config"

# Check the source directory exists
test -d "${SRC_DIR}" || exit 1

# If we have a 'clone' directory then we are running via GitHub Actions
# so change to that directory to have a consistent path structure for the following code.
if [ -d clone ]; then
  cd clone
fi

# Get the latest tag from the GitHub API.
HOME_ASSISTANT_CORE_LATEST_TAG="$(git ls-remote --tags origin 2>&1 | awk -F 'refs/tags/' '{print $2}' | sort -V | grep -E '\d{4}\.\d\.\d$' | tail -n 1)"

# Clean out the old data if it exists.
cd "${START_DIR}"
if [[ -d custom_components ]]; then
  rm -rf custom_components
fi

# Create somewhere for our updated code to go.
mkdir -p custom_components/default_config
cd custom_components/default_config

# Copy over the upstream files
cp -Rpf "${START_DIR}/core/homeassistant/components/default_config" "${START_DIR}/custom_components"

# Calculate last line of file
LINE="$(grep --line-number '}' "${START_DIR}/custom_components/default_config/manifest.json" | awk -F ':' '{print $1}')"

# Add in required data for the component to get loaded
# sed -i -r 's/^(\s+.+\:.*[^,]")$/\1,/' "${START_DIR}/custom_components/default_config/manifest.json"
cat <<<$(jq ". + { "version": \"${HOME_ASSISTANT_CORE_LATEST_TAG}.1\" }" ${START_DIR}/custom_components/default_config/manifest.json) >${START_DIR}/custom_components/default_config/manifest.json

# Disable the 'cloud' integration.
cat <<<$(jq 'del(.dependencies[] | select(. == "cloud"))' ${START_DIR}/custom_components/default_config/manifest.json) >${START_DIR}/custom_components/default_config/manifest.json

# Update hacs.json with the minimum homeassistant value for the latest release
cat <<<$(jq ".homeassistant = \"${HOME_ASSISTANT_CORE_LATEST_TAG}\"" ${START_DIR}/hacs.json) >${START_DIR}/hacs.json
