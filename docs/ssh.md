# SSH

## Remote Port Forwarding
If you want to expose a local port (from your local machine) on a remote machine, that's 
reachable beyond localhost, `GatewayPorts` must be allowed in the server configuration.

## Only allow the use of port forwardings
By specifying `ForceCommand echo` in the server configuration, you can remove the ability 
to execute commands from the clients.

## Unattended SSH (for Port Fowardings)
You can configure your SSH client to exclusively manage port forwarding without initiating 
a shell prompt by utilizing the following options: `-fCqN`
- `-f`: Forks the process to the background
- `-C`: Compresses the data before sending it
- `-q`: Uses quiet mode
- `-N`: Tells SSH that no command will be sent once the tunnel is up
