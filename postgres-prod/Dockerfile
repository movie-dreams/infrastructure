ARG POSTGRES_VERSION=17

FROM postgres:${POSTGRES_VERSION}-alpine

# Logging razonable para VPS (evitar log_statement=all en producción)
CMD ["postgres", "-c", "log_min_duration_statement=500"]
