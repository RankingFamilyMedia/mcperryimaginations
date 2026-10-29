<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, X-AutoYaad-Upload-Token');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function respond(int $status, array $body): void
{
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_SLASHES);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(405, ['error' => 'POST is required.']);
}

$configPath = '/home/grinircc/autoyaad-upload-config.php';
if (!is_file($configPath)) {
    respond(500, ['error' => 'Upload service is not configured.']);
}

$config = require $configPath;
$expectedToken = (string)($config['token'] ?? '');
$providedToken = (string)($_SERVER['HTTP_X_AUTOYAAD_UPLOAD_TOKEN'] ?? '');
if ($expectedToken === '' || !hash_equals($expectedToken, $providedToken)) {
    respond(401, ['error' => 'Upload authorization failed.']);
}

$owner = preg_replace('/[^A-Za-z0-9_-]/', '', (string)($_POST['owner'] ?? ''));
if ($owner === '') {
    respond(400, ['error' => 'A valid owner is required.']);
}

if (!isset($_FILES['file']) || !is_array($_FILES['file'])) {
    respond(400, ['error' => 'No image file was received.']);
}

$file = $_FILES['file'];
if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK) {
    respond(400, ['error' => 'The image upload failed.', 'code' => (int)$file['error']]);
}

$maxBytes = 8 * 1024 * 1024;
$size = (int)($file['size'] ?? 0);
if ($size <= 0 || $size >= $maxBytes) {
    respond(413, ['error' => 'Each image must be smaller than 8 MB.']);
}

$tmpName = (string)($file['tmp_name'] ?? '');
if (!is_uploaded_file($tmpName)) {
    respond(400, ['error' => 'Invalid upload data.']);
}

$finfo = new finfo(FILEINFO_MIME_TYPE);
$mime = (string)$finfo->file($tmpName);
$extensions = [
    'image/jpeg' => 'jpg',
    'image/png' => 'png',
    'image/webp' => 'webp',
];
if (!isset($extensions[$mime])) {
    respond(415, ['error' => 'Only JPG, PNG, and WebP images are allowed.']);
}

$baseDirectory = rtrim((string)$config['uploadDirectory'], '/');
$ownerDirectory = $baseDirectory . '/' . $owner;
if (!is_dir($ownerDirectory) && !mkdir($ownerDirectory, 0750, true)) {
    respond(500, ['error' => 'Could not create the image directory.']);
}

$filename = bin2hex(random_bytes(18)) . '.' . $extensions[$mime];
$target = $ownerDirectory . '/' . $filename;
if (!move_uploaded_file($tmpName, $target)) {
    respond(500, ['error' => 'Could not save the image.']);
}

respond(201, [
    'url' => rtrim((string)$config['publicBaseUrl'], '/') . '/' . rawurlencode($owner) . '/' . $filename,
]);
