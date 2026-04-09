FROM nginx:alpine

# Copy landing page and assets
COPY index.html /usr/share/nginx/html/index.html
COPY assets/ /usr/share/nginx/html/assets/

# Railway injects PORT env var — nginx must listen on it
RUN echo 'server { \
  listen $PORT; \
  root /usr/share/nginx/html; \
  index index.html; \
  location / { try_files $uri $uri/ /index.html; } \
  gzip on; \
  gzip_types text/html text/css application/javascript image/svg+xml; \
}' > /etc/nginx/conf.d/default.conf

# Use shell form so $PORT is expanded at runtime
CMD sh -c "sed -i 's/\$PORT/'"$PORT"'/g' /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"

EXPOSE 8080
