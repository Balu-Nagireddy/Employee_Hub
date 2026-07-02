FROM krakend:2.9.3

COPY krakend.json /etc/krakend/krakend.json

EXPOSE 8080 8090

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
