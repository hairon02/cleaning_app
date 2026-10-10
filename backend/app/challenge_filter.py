"""Safety checks for generated challenges before they enter the review bank."""

import re
import unicodedata

_UNSAFE_PHRASES = (
    "roof",
    "rooftop",
    "rooftops",
    "cliff",
    "ledge",
    "high-rise",
    "high place",
    "height",
    "heights",
    "night",
    "nights",
    "after dark",
    "darkness",
    "dark",
    "private property",
    "private land",
    "trespass",
    "restricted area",
    "abandoned building",
    "propiedad privada",
    "terreno privado",
    "azotea",
    "techo",
    "acantilado",
    "borde",
    "altura",
    "alturas",
    "de noche",
    "noche",
    "oscuridad",
    "edificio abandonado",
    "zona restringida",
    "invade",
)


def _normalize(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value.casefold())
    without_accents = "".join(char for char in normalized if not unicodedata.combining(char))
    return re.sub(r"[^a-z0-9]+", " ", without_accents).strip()


def is_safe(challenge: object) -> bool:
    """Return False when challenge text suggests an unsafe or private location."""
    if isinstance(challenge, dict):
        fields = (
            challenge.get("title", ""),
            challenge.get("description", ""),
            challenge.get("visual_criterion", ""),
        )
    else:
        fields = (
            getattr(challenge, "title", ""),
            getattr(challenge, "description", ""),
            getattr(challenge, "visual_criterion", ""),
        )
    content = f" {_normalize(' '.join(str(field) for field in fields))} "
    return not any(f" {_normalize(phrase)} " in content for phrase in _UNSAFE_PHRASES)
