#!/usr/bin/env bash
source scripts/evidence.sh
linux_lab() {
  local scratch; scratch=$(mktemp -d)
  cd "$scratch"
  echo 'Mayank Gupta 24BCS10220' > original.txt
  ln original.txt hard.txt; ln -s original.txt soft.txt
  ls -li original.txt hard.txt soft.txt
  test "$(stat -c %i original.txt)" = "$(stat -c %i hard.txt)"
  rm original.txt; test -f hard.txt; test -L soft.txt; test ! -e soft.txt
  cat hard.txt; whoami; uname -a
  echo 'PASS: hard link survives; symbolic link becomes dangling'
}
shell_lab() {
  local scratch; scratch=$(mktemp -d)
  cd "$scratch"
  printf 'mayank-report\nprocess.log\n' | bash "$ROOT/Shell Scripting/sysinfo.sh"
  test -s mayank-report/process.log
  head -3 mayank-report/process.log
}
network_lab() {
  ip -brief address; ip route; hostname
  getent hosts github.com
  curl --fail --head --max-time 30 https://github.com
  ss -tuln
}
git_lab() {
  local scratch; scratch=$(mktemp -d)
  cd "$scratch"; git init -b main
  git config user.name 'Mayank Gupta'; git config user.email 'mayank-0789@users.noreply.github.com'
  echo one > notes.txt; git add notes.txt; git commit -m 'Initial tracked file'
  echo two >> notes.txt; echo new > new.txt
  git commit -am 'Update tracked file'; test -n "$(git ls-files --others)"
  git checkout -b feature; echo 'Mayank feature' > feature.txt
  git add feature.txt; git commit -m 'Feature for cherry-pick'
  local feature_sha; feature_sha=$(git rev-parse HEAD)
  git checkout main; git cherry-pick "$feature_sha"
  git log --oneline --all; git status --short; cat feature.txt
}
docker_apps() {
  local dir tag port body
  port=8100
  for dir in nodejs-app python-app java-app Apache-app React-app nginx-app; do
    tag="mayank-lab-${dir,,}"
    docker build -q -t "$tag" "Docker Fundamentals/$dir"
    case "$dir" in nodejs-app) target=3000;; python-app) target=5000;; java-app) target=8080;; *) target=80;; esac
    docker run -d --name "$tag" -p "$port:$target" "$tag"
    for _ in $(seq 1 30); do curl -fsS "http://localhost:$port" >/tmp/app-response && break || sleep 2; done
    cat /tmp/app-response
    grep -qi mayank /tmp/app-response
    docker rm -f "$tag"
    port=$((port+1))
  done
  docker images --filter reference='mayank-lab-*'
}
multi_stage() {
  docker build -q -t mayank-multistage 'DockerFiles and Images'
  docker run -d --name mayank-multistage -p 8180:8080 mayank-multistage
  sleep 2; curl --fail http://localhost:8180
  docker image inspect mayank-multistage --format 'Final image size bytes: {{.Size}}'
  docker rm -f mayank-multistage
}
docker_networks() {
  docker network create mayank-front; docker network create mayank-back
  docker run -d --name mayank-front --network mayank-front nginx:alpine
  docker run -d --name mayank-back --network mayank-back nginx:alpine
  docker network connect mayank-front mayank-back
  docker exec mayank-front wget -qO- http://mayank-back | head -5
  docker network inspect mayank-front --format '{{json .Containers}}'
  docker run -d --name mayank-bind -p 8181:80 -v "$ROOT/Docker Networks/site:/usr/share/nginx/html:ro" nginx:alpine
  sleep 2; curl --fail http://localhost:8181
  docker rm -f mayank-front mayank-back mayank-bind
  docker network rm mayank-front mayank-back
}
evidence 'Linux Fundamentals' linux_lab
evidence 'Shell Scripting' shell_lab
evidence 'Networking Fundamentals' network_lab
evidence 'Git and Github' git_lab
evidence 'Docker Fundamentals' docker_apps
evidence 'DockerFiles and Images' multi_stage
evidence 'Docker Networks' docker_networks
