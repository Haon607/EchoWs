$SSH_HOST         = "192.168.0.6"
$SSH_USER         = "rb"
$CONTAINER_NAME   = "websocket"
$DESTINATION_PORT = 3000

$REMOTE_DIR = $CONTAINER_NAME
$IMAGE_NAME = "echo-ws"

$ErrorActionPreference = "Stop"

try {
    New-Item -ItemType Directory -Force -Path ".\todeploy" | Out-Null

    Copy-Item ".\app.js" -Destination ".\todeploy"
    Copy-Item ".\Dockerfile" -Destination ".\todeploy"
    Copy-Item ".\package.json" -Destination ".\todeploy"

    Compress-Archive -Path ".\todeploy\*" -DestinationPath ".\todeploy\deploy.zip" -Force

    ssh "$SSH_USER@$SSH_HOST" "mkdir -p '$REMOTE_DIR'"

    scp ".\todeploy\deploy.zip" "${SSH_USER}@${SSH_HOST}:$REMOTE_DIR/"

    if ($LASTEXITCODE -ne 0) {
        throw "Upload failed"
    }

    ssh "$SSH_USER@$SSH_HOST" "cd '$REMOTE_DIR' && unzip -o deploy.zip && rm deploy.zip && docker build -t '$IMAGE_NAME' ."

    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed"
    }

    ssh "$SSH_USER@$SSH_HOST" "docker rm -f '$CONTAINER_NAME' 2>/dev/null || true; docker run -d -p ${DESTINATION_PORT}:3000 --restart unless-stopped --name '$CONTAINER_NAME' '$IMAGE_NAME'"

    if ($LASTEXITCODE -ne 0) {
        throw "Container deployment failed"
    }

    ssh "$SSH_USER@$SSH_HOST" "rm -rf '$REMOTE_DIR'/*"

    Write-Host "Deployment successful!" -ForegroundColor Green
}
finally {
    Remove-Item -Path ".\todeploy" -Recurse -Force -ErrorAction SilentlyContinue
}
