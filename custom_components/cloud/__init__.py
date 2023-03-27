"""Cloud."""
from __future__ import annotations

DOMAIN = "cloud"

from homeassistant.core import HomeAssistant, callback
from homeassistant.helpers.typing import ConfigType
from homeassistant.loader import bind_hass

@bind_hass
@callback
def async_remote_ui_url(hass: HomeAssistant) -> str:
    return ""


async def async_setup(hass: HomeAssistant, config: ConfigType) -> bool:
    return False