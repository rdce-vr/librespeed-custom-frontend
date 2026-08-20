# Custom LibreSpeed Neo-HIG Speed Test Frontend

This repository houses a customized, high-contrast, modern UI frontend for LibreSpeed. It features Apple HIG-inspired styling, high-contrast light and dark modes, dynamic ping sweep loader animations, a responsive mobile simulator mode, and a clean scorecard layout with screenshot/sharing options.

---

## Docker Stack Integration (Zero Backend Changes)

If you are running the official LibreSpeed backend container (`ghcr.io/librespeed/speedtest`), you can drop this custom frontend container right in front of it. 

Your browser will connect to the **custom frontend** (mapping to your original port `8378`), which will serve the static Apple HIG-themed page. Any speed testing or database telemetry calls (`empty.php`, `garbage.php`, `getIP.php`, `telemetry.php`) are transparently proxied by Nginx internally to the backend `speedtest` container over port `8080`.

```
                    ┌──────────────────────────┐
                    │      Client Browser      │
                    └─────────────┬────────────┘
                                  │ Port 8378 (Public URL)
                                  ▼
         ┌──────────────────────────────────────────────────┐
         │              Custom Frontend Container           │
         │                  (Nginx Server)                  │
         ├────────────────────────┬─────────────────────────┤
         │ Static Assets          │ Reverse Proxy Routing   │
         │ (index.html, CSS)      │ (empty.php, getIP.php)  │
         └────────────────────────┴───────────┬─────────────┘
                                              │ Docker Internal Network (Port 8080)
                                              ▼
                             ┌──────────────────────────────────┐
                             │    Official LibreSpeed Backend   │
                             │         (speedtest container)        │
                             └──────────────────────────────────┘
```

---

## 1. How to Run with `docker-compose.yml`

A pre-configured [`docker-compose.yml`](file:///C:/Users/kreshna.putra/.gemini/antigravity/scratch/speed-test/docker-compose.yml) file has been generated in the root of this folder. You can use it directly:

```yaml
services:
  # 1. Custom High-Contrast Apple-HIG Frontend (serves on public port 8378)
  librespeed-frontend:
    image: docker.io/trans19/librespeed-custom-frontend:latest
    container_name: librespeed-frontend
    ports:
      - "8378:80" # Map host port 8378 to nginx port 80 (Drop-in replacement for the old web address!)
    environment:
      - BACKEND_HOST=speedtest
      - BACKEND_PORT=8080
    restart: always
    depends_on:
      - speedtest

  # 2. Existing LibreSpeed Backend (Handles telemetry, obfuscation, and tests)
  speedtest:
    container_name: speedtest
    image: ghcr.io/librespeed/speedtest:latest
    restart: always
    environment:
      MODE: standalone
      TITLE: RDCE-VR Server Test
      TELEMETRY: enable
      ENABLE_ID_OBFUSCATION: enable
      PASSWORD: change-this-db-password
      DISABLE_IPINFO: false
      DISTANCE: km
    # Note: Removed the host port mapping here so that the backend is private.
    # Nginx will securely route all speed tests internally over the Docker network.
```

### Steps to Deploy:
1. Save this compose stack to a server directory.
2. Build and push the frontend image to your GitHub Container Registry (`ghcr.io`) (see section below).
3. Start the containers:
   ```bash
   docker compose up -d
   ```
4. Visit `http://your-server-ip:8378` in your browser.

---

## 2. How to Build & Publish the Frontend to GHCR

### A. Login to GitHub Container Registry
Generate a GitHub Personal Access Token (PAT) with `write:packages` scope, then run:
```bash
echo $YOUR_GITHUB_TOKEN | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

### B. Build the Docker Image
From the root of this directory:
```bash
docker build -t ghcr.io/YOUR_GITHUB_USERNAME/librespeed-custom-frontend:latest .
```

### C. Push the Image to GHCR
```bash
docker push ghcr.io/YOUR_GITHUB_USERNAME/librespeed-custom-frontend:latest
```

Once pushed, remember to change the `image:` value in your `docker-compose.yml` file from `ghcr.io/<your-github-username>/librespeed-custom-frontend:latest` to your actual GitHub package path.

---

## 3. Bare Metal Setup (Non-Docker Web Servers)

If you are running LibreSpeed directly on the server host:

1. Locate your web server document root (e.g. `/var/www/html/` or `/usr/share/nginx/html/`).
2. Move your old frontend files to a backup folder:
   ```bash
   mv /var/www/html/index.html /var/www/html/index.html.backup
   ```
3. Copy the files in this directory to your webroot:
   ```bash
   cp -R styling/ /var/www/html/
   cp index_librespeed.html /var/www/html/index.html
   ```
4. Reset permissions:
   ```bash
   chown -R www-data:www-data /var/www/html/
   chmod -R 755 /var/www/html/
   ```
5. Reload Nginx/Apache:
   ```bash
   sudo systemctl reload nginx
   ```
