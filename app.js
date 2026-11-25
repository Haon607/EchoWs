const WebSocket = require('ws');

const wss = new WebSocket.Server({port: 3000});

wss.on('connection', function connection(ws) {
    console.log('Client connected!');

    ws.on('message', async function incoming(data) {
        const msg = JSON.parse(data);
        console.log(msg);
        broadcast(msg);
    });
});

function broadcast(msg) {
    const data = JSON.stringify(msg);
    wss.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(data);
        }
    });
}
