# Custom LibreSpeed Neo-HIG Speed Test Frontend

This repository houses a customized, high-contrast, modern UI frontend for LibreSpeed. It features Apple HIG-inspired styling, high-contrast light and dark modes, dynamic ping sweep loader animations, a responsive mobile simulator mode, and a clean scorecard layout with screenshot/sharing options.

The project is designed to run seamlessly alongside a LibreSpeed backend stack inside Docker, or as a drop-in replacement on bare metal web servers.

---

## Architecture Diagram (Docker Stack)

When deploying via Docker, the frontend runs in its own container and reverse-proxies the LibreSpeed telemetric endpoints (`empty.php`, `garbage.php`, `getIP.php`, `telemetry.php`) directly to the LibreSpeed backend service in the same network. This allows you to deploy the customized interface without changing any files or configurations in the official LibreSpeed backend container!

```
                    ┌──────────────────────────┐
                    │      Client Browser      │
                    └─────────────┬────────────┘
                                  │ Port 8080 (Public URL)
                                  ▼
         ┌──────────────────────────────────────────────────┐
         │              Custom Frontend Container           │
         │                  (Nginx Server)                  │
         ├────────────────────────┬─────────────────────────┤
         │ Static Assets          │ Reverse Proxy Routing   │
         │ (index.html, CSS)      │ (empty.php, getIP.php)  │
         └────────────────────────┴───────────┬─────────────┘
                                              │ Docker Internal Network
                                              ▼
                             ┌──────────────────────────────────┐
                             │    Official LibreSpeed Backend   │
                             │        (PHP/Go Telemetry API)     │
                             └──────────────────────────────────┘
```

---

## 1. Docker Deployment (Recommended)

### A. Pre-built Docker Image (Using GHCR)
You can pull the pre-built image from GitHub Container Registry (once pushed):
```bash
docker pull ghcr.io/<your-github-username>/librespeed-custom-frontend:latest
```

### B. Setup with `docker-compose.yml`
Create a folder for your stack and save the following `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  # 1. Custom High-Contrast UI Frontend (This repository)
  librespeed-frontend:
    image: ghcr.io/<your-github-username>/librespeed-custom-frontend:latest
    container_name: librespeed-frontend
    ports:
      - "8080:80" # Map to any public port you want (e.g. 8080)
    environment:
      - BACKEND_HOST=librespeed-backend
      - BACKEND_PORT=80
    restart: unless-stopped
    depends_on:
      - librespeed-backend

  # 2. Official LibreSpeed Backend (Handles speed test endpoints & telemetry)
  librespeed-backend:
    image: librespeed/speedtest:latest
    container_name: librespeed-backend
    environment:
      - TZ=UTC
      - TELEMETRY=true
      - PASSWORD=change-this-telemetry-db-password
    restart: unless-stopped
```

Deploy the stack:
```bash
docker compose up -d
```
Access the custom speed test at `http://localhost:8080`.

---

## 2. How to Build & Publish your own Docker Image

If you make modifications and want to build and publish your own image to GitHub Container Registry (`ghcr.io`), follow these steps:

### A. Login to GHCR
First, create a GitHub Personal Access Token (PAT) with `write:packages` scope, then log in:
```bash
echo $YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

### B. Build and Tag
From the root of this project:
```bash
docker build -t ghcr.io/YOUR_GITHUB_USERNAME/librespeed-custom-frontend:latest .
```

### C. Push the Image
```bash
docker push ghcr.io/YOUR_GITHUB_USERNAME/librespeed-custom-frontend:latest
```

---

## 3. Bare Metal / Standard Web Server Deployment

If you are running LibreSpeed directly on a web server (like Nginx, Apache, or Caddy) on bare metal without Docker:

### A. Install LibreSpeed Backend
Make sure you have installed the official LibreSpeed backend (usually PHP or Go daemon). Verify that visiting `http://your-server-ip/empty.php` or `getIP.php` returns a valid response.

### B. Install Custom Frontend
1. Locate the public document root of your web server (e.g., `/var/www/html/` or `/usr/share/nginx/html/`).
2. Backup or remove your old files:
   ```bash
   mv /var/www/html/index.html /var/www/html/index.html.backup
   ```
3. Copy the contents of this repository into the document root:
   ```bash
   cp -R styling/ /var/www/html/
   # Copy index_librespeed.html as index.html so it serves as the entry page
   cp index_librespeed.html /var/www/html/index.html
   ```
4. Check permissions to ensure the web server can read the files:
   ```bash
   chown -R www-data:www-data /var/www/html/
   chmod -R 755 /var/www/html/
   ```
5. Reload your web server:
   ```bash
   sudo systemctl reload nginx
   # OR
   sudo systemctl reload apache2
   ```

---

## Project Structure

* **`index.html`**: Local simulation file. Useful for frontend visual testing without running a live speedtest server. (Serves as `index_sim.html` in container).
* **`index_librespeed.html`**: Active telemetry frontend. Configured to talk to the local reverse-proxy path. (Serves as the main `index.html` entrypoint in container).
* **`styling/results_animation.css`**: Complete high-contrast typography, theme, and animation parameters.
* **`default.conf.template`**: Nginx proxy template processed dynamically by environment variables in Docker.
* **`Dockerfile`**: Light alpine-nginx packaging build script.
