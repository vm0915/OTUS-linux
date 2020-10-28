FROM alpine:3.12.1
RUN mkdir -p /run/nginx \
    && apk add nginx
COPY nginx.conf /etc/nginx/nginx.conf 
COPY index.html /var/lib/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
