# Docker Fundamentals - Mayank's Hello World Applications

> Adapted lab walkthrough for Mayank Gupta (24BCS10220). Commands and output blocks below are reference examples from the source material, not a claim that this machine ran them. Imported screenshots were omitted. See [source provenance](../SOURCE.md).


**Author:** Mayank Gupta
**Roll No:** 24BCS10220

My Docker Fundamentals homework. I built six simple "Hello World" web applications, one per
technology, and containerized each of them with its own Dockerfile. Every app prints a
personalised greeting ("Hello World from Mayank's ... app!") so I can confirm in the browser
that it is really my container responding.

## What I built
| App | Technology | What it does |
|---|---|---|
| nodejs-app | Node.js 20 (built-in `http` module) | Tiny HTTP server that returns my greeting |
| python-app | Python 3.12 + Flask | Flask route `/` that returns my greeting |
| java-app | Java 21 (built-in `HttpServer`) | Compiled inside the image, serves my greeting |
| Apache-app | Apache HTTP Server 2.4 | Serves a static `index.html` |
| React-app | React 18, multi-stage build, served by Nginx | Builds the production bundle, then Nginx serves it |
| nginx-app | Nginx (alpine) | Serves a static `index.html` |

## Folder structure
```
Docker Fundamentals/
├── nodejs-app/     Node.js (built-in http server)
├── python-app/     Python (Flask)
├── java-app/       Java (built-in HttpServer)
├── Apache-app/     Apache HTTP Server (static page)
├── React-app/      React (built + served by Nginx)
├── nginx-app/      Nginx (static page)
└── screenshots/    Browser screenshots of each app
```

## Ports summary
I tagged every image with a `mayank-` prefix so my images are easy to spot in `docker images`.
Python is mapped to host port 5001 because macOS AirPlay Receiver already listens on port 5000 on my Mac.

| App | Container port | Host port I used | Run command |
|---|---|---|---|
| nodejs-app | 3000 | 3000 | `docker run -d -p 3000:3000 mayank-nodejs-app` |
| python-app | 5000 | 5001 | `docker run -d -p 5001:5000 mayank-python-app` |
| java-app | 8080 | 8080 | `docker run -d -p 8080:8080 mayank-java-app` |
| Apache-app | 80 | 8081 | `docker run -d -p 8081:80 mayank-apache-app` |
| React-app | 80 | 8082 | `docker run -d -p 8082:80 mayank-react-app` |
| nginx-app | 80 | 8083 | `docker run -d -p 8083:80 mayank-nginx-app` |

## How I built and ran each app
All commands are run from inside the `Docker Fundamentals` folder.

### 1. Node.js
```bash
cd nodejs-app
docker build -t mayank-nodejs-app .
docker run -d --name mayank-nodejs -p 3000:3000 mayank-nodejs-app
# open http://localhost:3000  ->  "Hello World from Mayank's Node.js app!"
```

### 2. Python (Flask)
```bash
cd python-app
docker build -t mayank-python-app .
docker run -d --name mayank-python -p 5001:5000 mayank-python-app
# open http://localhost:5001  ->  "Hello World from Mayank's Python (Flask) app!"
```

### 3. Java
```bash
cd java-app
docker build -t mayank-java-app .
docker run -d --name mayank-java -p 8080:8080 mayank-java-app
# open http://localhost:8080  ->  "Hello World from Mayank's Java app!"
```

### 4. Apache HTTP Server
```bash
cd Apache-app
docker build -t mayank-apache-app .
docker run -d --name mayank-apache -p 8081:80 mayank-apache-app
# open http://localhost:8081  ->  "Hello World from Mayank's Apache HTTP Server!"
```

### 5. React (multi-stage build + Nginx)
```bash
cd React-app
docker build -t mayank-react-app .
docker run -d --name mayank-react -p 8082:80 mayank-react-app
# open http://localhost:8082  ->  "Hello World from Mayank's React app!"
```

### 6. Nginx
```bash
cd nginx-app
docker build -t mayank-nginx-app .
docker run -d --name mayank-nginx -p 8083:80 mayank-nginx-app
# open http://localhost:8083  ->  "Hello World from Mayank's Nginx server!"
```

## Verifying from the terminal
```bash
docker images | grep mayank          # all six of my images
docker ps                             # all six containers running
curl http://localhost:3000            # Node.js greeting
curl http://localhost:5001            # Python greeting
curl http://localhost:8080            # Java greeting
curl http://localhost:8081            # Apache greeting
curl http://localhost:8082            # React greeting (text is rendered by the JS bundle)
curl http://localhost:8083            # Nginx greeting
```

## Cleaning up
```bash
docker stop mayank-nodejs mayank-python mayank-java mayank-apache mayank-react mayank-nginx
docker rm   mayank-nodejs mayank-python mayank-java mayank-apache mayank-react mayank-nginx
docker rmi  mayank-nodejs-app mayank-python-app mayank-java-app mayank-apache-app mayank-react-app mayank-nginx-app
```

## Useful Docker commands I used
```bash
docker images            # list built images
docker ps -a             # list all containers (running and stopped)
docker logs <container>  # view container logs
docker exec -it <container> sh   # open a shell inside a running container
docker stop <container>  # stop a container
docker rm <container>    # remove a container
docker rmi <image>       # remove an image
```

## What I learned
- A Dockerfile is a recipe: `FROM` picks a base image, `COPY` adds my code, `RUN` executes build
  steps, `EXPOSE` documents the port, and `CMD` says what to start.
- Container port vs host port: `-p 8081:80` maps host 8081 to the container's 80, which is how
  Apache, React and Nginx can all run at the same time even though they all listen on 80 inside.
- Multi-stage builds (React app) keep the final image small: Node is only needed to build,
  so the final stage is just Nginx plus the static files.
- `.dockerignore` stops `node_modules` from being copied into the image and slowing the build.

## Screenshots
Terminal view: my six images, all six containers running, and `curl` against every port:


Each browser screenshot below shows the app running in my container with my personalised greeting.

- Node.js:
- Python:
- Java:
- Apache:
- React:
- Nginx:
