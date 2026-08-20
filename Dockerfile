FROM nginx:alpine

# Copy static Nginx configuration directly to conf.d, overwriting default config
COPY default.conf /etc/nginx/conf.d/default.conf

RUN rm -rf /usr/share/nginx/html/*

COPY styling /usr/share/nginx/html/styling
COPY index_librespeed.html /usr/share/nginx/html/index.html

EXPOSE 80
