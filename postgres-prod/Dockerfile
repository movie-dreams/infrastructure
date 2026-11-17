ARG POSTGRES_VERSION=17

FROM postgres:${POSTGRES_VERSION}-alpine

CMD ["postgres","-c","log_statement=all","-c","log_min_duration_statement=0"]