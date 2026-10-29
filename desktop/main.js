const { app, BrowserWindow, dialog } = require('electron');
const fs = require('fs');
const http = require('http');
const path = require('path');

const mimeTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.ttf': 'font/ttf',
  '.wasm': 'application/wasm',
  '.webp': 'image/webp',
};

let localServer;

function cmsRoot() {
  return app.isPackaged
    ? path.join(process.resourcesPath, 'cms_web')
    : path.resolve(__dirname, '..', 'build', 'web');
}

function startLocalServer(root) {
  return new Promise((resolve, reject) => {
    const server = http.createServer((request, response) => {
      let pathname;
      try {
        pathname = decodeURIComponent(new URL(request.url, 'http://127.0.0.1').pathname);
      } catch (_) {
        response.writeHead(400);
        response.end('Bad request');
        return;
      }

      let filePath = path.resolve(root, `.${pathname}`);
      if (!filePath.startsWith(`${path.resolve(root)}${path.sep}`)) {
        response.writeHead(403);
        response.end('Forbidden');
        return;
      }
      if (pathname.endsWith('/') || !fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
        filePath = path.join(root, 'index.html');
      }

      fs.readFile(filePath, (error, data) => {
        if (error) {
          response.writeHead(404);
          response.end('Not found');
          return;
        }
        response.writeHead(200, {
          'Cache-Control': pathname === '/' ? 'no-store' : 'public, max-age=3600',
          'Content-Type': mimeTypes[path.extname(filePath).toLowerCase()] || 'application/octet-stream',
        });
        response.end(data);
      });
    });

    server.once('error', reject);
    server.listen(0, '127.0.0.1', () => resolve(server));
  });
}

async function openCms() {
  const root = cmsRoot();
  if (!fs.existsSync(path.join(root, 'index.html'))) {
    dialog.showErrorBox(
      'AutoYaad CMS files not found',
      'Rebuild the CMS web release and reinstall AutoYaad CMS.'
    );
    app.quit();
    return;
  }

  localServer = await startLocalServer(root);
  const port = localServer.address().port;
  const window = new BrowserWindow({
    width: 1440,
    height: 960,
    minWidth: 1080,
    minHeight: 700,
    title: 'AutoYaad CMS',
    backgroundColor: '#f8f9fa',
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });
  window.removeMenu();
  window.loadURL(`http://127.0.0.1:${port}/`);
  window.on('closed', () => localServer?.close());
}

app.setAppUserModelId('com.mcperryimaginations.autoyaad.cms');
app.whenReady().then(openCms);
app.on('window-all-closed', () => app.quit());
