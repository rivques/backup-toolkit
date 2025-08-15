# wol-proxy
Quick-and-dirty tool to allow remote machines to wake someone.

## Usage
Run the Dockerfile. Then, connect to the hosted TCP socket and send "wake".

Available environment variables:
- `MAC_ADDR`: MAC address of the machine to wake. Default: `00:11:22:33:44:55`
- `LISTEN_ADDR`: Address to listen on. Default: `127.0.0.1:9253`