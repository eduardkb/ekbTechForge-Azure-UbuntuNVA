#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Install Nginx and PHP-FPM
apt-get update
apt-get install -y nginx php-fpm

# Create the dynamic web page
cat > /var/www/html/index.php <<'PHP'
<?php
function h($value): string {
    return htmlspecialchars((string)$value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function pretty($value): string {
    return json_encode(
        $value,
        JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE
    ) ?: 'null';
}

$hostname = gethostname() ?: 'unknown';
$headers = function_exists('getallheaders') ? getallheaders() : [];
$rawBody = file_get_contents('php://input');

$requestData = [
    'Method'          => $_SERVER['REQUEST_METHOD'] ?? '',
    'URI'             => $_SERVER['REQUEST_URI'] ?? '',
    'Query string'    => $_SERVER['QUERY_STRING'] ?? '',
    'Protocol'        => $_SERVER['SERVER_PROTOCOL'] ?? '',
    'Client IP'       => $_SERVER['REMOTE_ADDR'] ?? '',
    'Client port'     => $_SERVER['REMOTE_PORT'] ?? '',
    'Server IP'       => $_SERVER['SERVER_ADDR'] ?? '',
    'Server port'     => $_SERVER['SERVER_PORT'] ?? '',
    'Content type'    => $_SERVER['CONTENT_TYPE'] ?? '',
    'Content length'  => $_SERVER['CONTENT_LENGTH'] ?? '',
    'HTTP headers'    => $headers,
    'Query parameters'=> $_GET,
    'Form data'       => $_POST,
    'Cookies'         => $_COOKIE,
    'Raw request body'=> $rawBody,
];
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Azure Test Page</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1100px;
            margin: 40px auto;
            padding: 0 20px;
            color: #222;
        }
        .hostname {
            padding: 12px;
            background: #eef4ff;
            border-radius: 6px;
        }
        pre {
            padding: 16px;
            background: #f4f4f4;
            border: 1px solid #ddd;
            border-radius: 6px;
            overflow-x: auto;
            white-space: pre-wrap;
            overflow-wrap: anywhere;
        }
    </style>
</head>
<body>
    <h3>Welcome, E.K.B.</h3>

    <div class="hostname">
        <strong>Server hostname:</strong>
        <?= h($hostname) ?>
    </div>

    <h2>Received HTTP Request</h2>
    <pre><?= h(pretty($requestData)) ?></pre>
</body>
</html>
PHP

# Configure Nginx to serve PHP and route requests to index.php
cat > /etc/nginx/sites-available/default <<'NGINX'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;
    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\. {
        deny all;
    }
}
NGINX

# Set permissions and start services
chown -R www-data:www-data /var/www/html
chmod 644 /var/www/html/index.php

nginx -t
systemctl enable --now php8.3-fpm
systemctl enable --now nginx
systemctl restart nginx