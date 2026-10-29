# Shared cPanel media service

The shared endpoint is:

`https://rankingfamily.com/media-api/upload.php`

Each app gets its own lowercase app ID, token, and media namespace. Add a new
app to `shared-media-config.php` without reusing another app's token. Images are
stored under `shared-media/{appId}/{ownerId}/` and the returned public URL is
saved in that app's database.
