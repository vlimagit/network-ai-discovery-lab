"""Minimal NetBox configuration for the isolated discovery lab."""
import os

ALLOWED_HOSTS = ["*"]  # Bind the published port to loopback by default.
SECRET_KEY = os.environ["NETBOX_SECRET_KEY"]

DATABASE = {
    "NAME": os.environ.get("DB_NAME", "netbox"),
    "USER": os.environ.get("DB_USER", "netbox"),
    "PASSWORD": os.environ["DB_PASSWORD"],
    "HOST": os.environ.get("DB_HOST", "postgres"),
    "PORT": os.environ.get("DB_PORT", "5432"),
    "CONN_MAX_AGE": 300,
}

REDIS = {
    "tasks": {
        "HOST": os.environ.get("REDIS_HOST", "redis"),
        "PORT": 6379,
        "PASSWORD": os.environ["REDIS_PASSWORD"],
        "DATABASE": 0,
        "SSL": False,
    },
    "caching": {
        "HOST": os.environ.get("REDIS_HOST", "redis"),
        "PORT": 6379,
        "PASSWORD": os.environ["REDIS_PASSWORD"],
        "DATABASE": 1,
        "SSL": False,
    },
}

TIME_ZONE = "Europe/Paris"
