FROM nginx:1.30-alpine

WORKDIR /etc/nginx

COPY ./nginx.conf ./nginx.conf

RUN mkdir -p ./sites-enabled ./sites-available \
    && rm -f ./conf.d/default.conf

COPY ./sites-prod/ ./sites-available/

# Enable all production vhosts (sites-enabled must not stay empty).
RUN ln -sf /etc/nginx/sites-available/client-cine-upea.bo.conf \
        /etc/nginx/sites-enabled/client-cine-upea.bo.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q --spider http://127.0.0.1:80/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
