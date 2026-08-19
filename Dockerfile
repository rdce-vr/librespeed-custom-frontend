FROM nginx:alpine

# Copy Nginx template for environment variable substitution
COPY default.conf.template /etc/nginx/templates/default.conf.template

# Default connection parameters for LibreSpeed backend container
ENV BACKEND_HOST=librespeed-backend
ENV BACKEND_PORT=80

# Clean default Nginx folder
RUN rm -rf /usr/share/nginx/html/*

# Copy assets
COPY styling /usr/share/nginx/html/styling
COPY index_librespeed.html /usr/share/nginx/html/index.html
COPY index.html /usr/share/nginx/html/index_sim.html

EXPOSE 80
