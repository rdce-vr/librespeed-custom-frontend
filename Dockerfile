FROM nginx:alpine

COPY default.conf.template /etc/nginx/templates/default.conf.template

ENV BACKEND_HOST=speedtest
ENV BACKEND_PORT=80

RUN rm -rf /usr/share/nginx/html/*

COPY styling /usr/share/nginx/html/styling
COPY index_librespeed.html /usr/share/nginx/html/index.html

EXPOSE 80
