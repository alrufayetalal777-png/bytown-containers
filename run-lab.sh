#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
export SEED=14
mkdir -p evidence
printf 'Student: Talal Al-Rufaye | ID: 101344712 | SEED: %s\n' "$SEED"
command -v docker >/dev/null || { echo 'ERROR: Docker not installed'; exit 1; }
docker info >/dev/null || { echo 'ERROR: Docker daemon is not running'; exit 1; }
docker compose version >/dev/null || { echo 'ERROR: Docker Compose unavailable'; exit 1; }

echo 'PART 0: Docker hello-world'
docker run --rm hello-world | tee evidence/part0-hello-world.txt

echo 'PART 1: nginx container'
docker rm -f "web-$SEED" >/dev/null 2>&1 || true
docker run -d --name "web-$SEED" -p "$((8000+SEED)):80" nginx:alpine
curl --fail --retry 5 --retry-connrefused --retry-delay 1 -sS "http://localhost:$((8000+SEED))" | head -5
sleep 1
docker logs "web-$SEED" > evidence/part1-logs.txt 2>&1
grep -q 'GET / HTTP/1.1' evidence/part1-logs.txt
docker rm -f "web-$SEED"

echo 'PART 2: image 1.0 and 1.1'
cp web/index.html web/index.html.bak
trap 'mv -f web/index.html.bak web/index.html 2>/dev/null || true' EXIT
sed '/<p>Version 1.1<\/p>/d' web/index.html.bak > web/index.html
docker build --build-arg "SEED=$SEED" -t bytown-web:1.0 ./web
docker rm -f "bytown-web-$SEED" >/dev/null 2>&1 || true
docker run -d --name "bytown-web-$SEED" -p "$((8100+SEED)):80" bytown-web:1.0
curl --fail --retry 5 --retry-connrefused --retry-delay 1 -sS "http://localhost:$((8100+SEED))" | tee evidence/part2-curl.txt
docker image inspect bytown-web:1.0 > evidence/part2-inspect.json
mv -f web/index.html.bak web/index.html
trap - EXIT
docker build --build-arg "SEED=$SEED" -t bytown-web:1.1 ./web
docker images bytown-web | tee evidence/part2-images.txt
docker rm -f "bytown-web-$SEED"

echo 'PART 3: persistent volume'
docker volume create "bytown-data-$SEED"
docker rm -f "vol-a-$SEED" "vol-b-$SEED" >/dev/null 2>&1 || true
docker run -d --name "vol-a-$SEED" -v "bytown-data-$SEED:/usr/share/nginx/html" nginx:alpine
docker exec "vol-a-$SEED" sh -c "echo seed=$SEED > /usr/share/nginx/html/status.txt"
docker rm -f "vol-a-$SEED"
docker run -d --name "vol-b-$SEED" -p "$((8200+SEED)):80" -v "bytown-data-$SEED:/usr/share/nginx/html" nginx:alpine
curl --fail --retry 5 --retry-connrefused --retry-delay 1 -sS "http://localhost:$((8200+SEED))/status.txt" | tee evidence/part3-curl.txt
grep -q "seed=$SEED" evidence/part3-curl.txt
docker rm -f "vol-b-$SEED"

echo 'PART 4: Compose'
cd stack
docker compose config > ../evidence/part4-config.txt
docker compose up -d --build
docker compose ps | tee ../evidence/part4-ps.txt
curl --fail --retry 8 --retry-connrefused --retry-delay 1 -sS "http://localhost:$((8300+SEED))" | tee ../evidence/part4-curl.txt
grep -q "Seed: $SEED" ../evidence/part4-curl.txt
if curl --fail -sS --max-time 3 "http://localhost:$((8100+SEED))" >/dev/null 2>&1; then
    echo 'ERROR: internal web port is unexpectedly reachable' | tee ../evidence/part4-isolation.txt
    exit 1
else
    echo 'not reachable, as intended' | tee ../evidence/part4-isolation.txt
fi
cd ..
if [[ -f "$HOME/net2008-devops/week09/lab/W09_Lab_selfcheck.py" ]]; then
    python3 "$HOME/net2008-devops/week09/lab/W09_Lab_selfcheck.py" --seed "$SEED" | tee evidence/selfcheck.txt
else
    echo 'Official self-check not found at expected course path; run it manually if available.' | tee evidence/selfcheck-not-found.txt
fi
cd stack
docker compose down
cd ..
docker ps -a | tee evidence/part5-docker-ps.txt
printf '\nDONE: Check generated evidence, commit, push, and submit your GitHub URL.\n'
