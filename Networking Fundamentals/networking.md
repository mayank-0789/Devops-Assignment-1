# Networking Fundamentals - Homework

> Adapted lab walkthrough for Mayank Gupta (24BCS10220). Commands and output blocks below are reference examples from the source material, not a claim that this machine ran them. Imported screenshots were omitted. See [source provenance](../SOURCE.md).


Practice of common Linux networking commands, with their output and a short explanation of what each one does.

## 1. ping
```bash
ping -c 4 google.com
```
Sends ICMP echo request packets to a host to check if it is reachable and how long the round trip takes. Useful for testing basic connectivity and measuring latency. `-c 4` limits it to 4 packets.

**What I understood:** `ping` tells me whether a server is up and how fast my connection to it is. If packets are lost or there is no reply, there is a network or DNS problem.


## 2. ip a (ip address)
```bash
ip a
```
Shows all network interfaces on the machine along with their IP addresses, MAC addresses, and status (up/down). This is the modern replacement for `ifconfig`.

**What I understood:** This is how I find my own machine's IP address and see which network interfaces exist (like `eth0`, `lo` for loopback).


## 3. ip route / route
```bash
ip route
```
Displays the routing table, including the default gateway (the router that traffic goes through to reach the internet).

**What I understood:** It shows the path packets take to leave my network. The `default via` line is my gateway/router.


## 4. netstat / ss
```bash
ss -tulpn
```
Lists network connections, listening ports, and the programs using them. `ss` is the faster modern replacement for `netstat`. Flags: `-t` TCP, `-u` UDP, `-l` listening, `-p` process, `-n` numeric.

**What I understood:** This shows which ports are open and which service is listening on each one. Useful to check if a server (like SSH on port 22) is running.


## 5. curl
```bash
curl -I https://www.google.com
```
Transfers data to or from a server. `-I` fetches only the HTTP response headers. Commonly used to test APIs and web endpoints.

**What I understood:** `curl` lets me talk to a web server from the terminal. The headers tell me the status code (e.g. `200 OK`) and server details.


## 6. wget
```bash
wget https://example.com/index.html
```
Downloads files from the internet over HTTP, HTTPS, or FTP. Unlike curl, it saves the file to disk by default.

**What I understood:** `wget` is for downloading files/pages directly to my machine.


## 7. nslookup / dig
```bash
nslookup google.com
```
Queries DNS to resolve a domain name into its IP address (and vice versa).

**What I understood:** This shows how a website name gets translated into an IP address by DNS. If this fails, the site name cannot be resolved.


## 8. traceroute
```bash
traceroute -I google.com
```
Shows the full path (each router/hop) that packets take to reach a destination, with the time at each hop. I used `-I` (ICMP echo probes instead of UDP) because the default UDP probes were dropped by the Docker Desktop NAT on my machine and every hop after the gateway showed `* * *`.

**What I understood:** It shows every stop between my machine and the destination, which helps find where a connection slows down or breaks.


## 9. hostname
```bash
hostname
hostname -I
```
Prints the name of the machine. `-I` prints its IP address(es).

**What I understood:** A quick way to see the machine's name and IP.


