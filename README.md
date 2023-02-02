# Home Assistant Cloud Hider
Custom Component for Home Assistant that hides "Home Assistant Cloud" from Home Assistant UI.

## Background
Home assistant has a cloud component that gets loaded automatically if you use the `default_config`. In order to delete cloud from your setup you need to delete the `defaul_config` and add manually add all the configurations back into your own `configuration.yaml`. Also you need to manually update it when things change in Home Assistant. 

This is an alternative to this process. It works by overriding the default component with a "dummy" one, thus eliminating it from the UI.

## Installation
[![hacs_badge](https://img.shields.io/badge/HACS-Custom-orange.svg)](https://github.com/custom-components/hacs)

The component can be installed from HACS (use the Custom Repository option), or follow the below instructions to install manually.
1. Create a folder in your `config` directory (normally where your configuration.yaml file lives) named `custom_components`
2. Create a folder in your `custom_components` named `cloud`
3. Copy the 2 files (_init_.py, manifest.json) into the `cloud` folder
4. Restart Home Assistant
