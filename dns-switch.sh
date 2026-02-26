#!/usr/bin/env bash
set -e

########################################
# Extended Iranian & Public DNS List
########################################

IR_DNS_LIST=(
"217.218.155.155"
"185.20.163.4"
"78.157.42.101"
"31.24.234.37"
"2.189.44.44"
"185.20.163.2"
"194.60.210.66"
"217.218.127.127"
"2.188.21.130"
"31.24.200.4"
"2.185.239.138"
"5.145.112.39"
"85.185.85.6"
"217.219.132.88"
"178.22.122.100"
"194.36.174.1"
"185.53.143.3"
"80.191.209.105"
"78.157.42.100"
"213.176.123.5"
"185.55.226.26"
"185.161.112.38"
"194.225.152.10"
"2.188.21.131"
"2.188.21.132"
"10.202.10.10"
"46.224.1.42"
"8.8.8.8"
"8.8.4.4"
"1.1.1.1"
"1.0.0.1"
"9.9.9.9"
"149.112.112.112"
)

LOCAL_DNS="127.0.0.1"

GREEN="\033[0;32m"
RED="\033[0;31m"
CYAN="\033[0;36m"
YELLOW="\033[1;33m"
NC="\033[0m"

pause() {
  echo
  read -rp "Press Enter to continue..." _
}

########################################
# DNSCrypt-Proxy Install & Setup
########################################

DNSCRYPT_CONFIG="/etc/dnscrypt-proxy/dnscrypt-proxy.toml"
DNSCRYPT_CONFIG_DIR="/etc/dnscrypt-proxy"

write_default_config() {
  echo ">> Writing default dnscrypt-proxy config..."
  mkdir -p "$DNSCRYPT_CONFIG_DIR"
  mkdir -p /var/log/dnscrypt-proxy
  mkdir -p /var/cache/dnscrypt-proxy

  cat > "$DNSCRYPT_CONFIG" <<'EOF'
##############################################
# dnscrypt-proxy configuration (Stable - Iran DC)
##############################################

# Listen on localhost only
listen_addresses = ['127.0.0.1:5053']

# Network behavior
ipv6_servers = false
block_ipv6 = true
require_dnssec = false

# Resolver selection (DoH resolvers - stable from Iran)
server_names = ['cloudflare', 'google', 'quad9-doh']

# Fallback DNS for downloading resolver list on first run
fallback_resolvers = ['8.8.8.8:53', '1.1.1.1:53']
ignore_system_dns = true

# Logging
[query_log]
  file = '/var/log/dnscrypt-proxy/query.log'

[nx_log]
  file = '/var/log/dnscrypt-proxy/nx.log'

##############################################
# Sources of public resolvers
##############################################

[sources]

  [sources.'public-resolvers']
  url = 'https://download.dnscrypt.info/resolvers-list/v2/public-resolvers.md'
  cache_file = '/var/cache/dnscrypt-proxy/public-resolvers.md'
  minisign_key = 'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3'
  refresh_delay = 72
  prefix = ''
EOF

  echo -e "${GREEN}>> Config written to $DNSCRYPT_CONFIG${NC}"
}

install_via_apt() {
  echo ">> Trying apt install..."
  if apt-get install -y dnscrypt-proxy >/dev/null 2>&1; then
    echo -e "${GREEN}>> dnscrypt-proxy installed via apt.${NC}"
    # apt version uses systemd socket activation on 127.0.2.1:53 — disable it
    # so we can control the listen address ourselves via config
    systemctl disable dnscrypt-proxy.socket >/dev/null 2>&1 || true
    systemctl stop dnscrypt-proxy.socket >/dev/null 2>&1 || true
    echo ">> systemd socket activation disabled."
    return 0
  else
    echo -e "${YELLOW}>> apt install failed.${NC}"
    return 1
  fi
}

install_via_binary() {
  echo ">> Trying binary install from GitHub..."

  local ARCH
  ARCH=$(uname -m)
  local BIN_ARCH
  case "$ARCH" in
    x86_64)  BIN_ARCH="x86_64" ;;
    aarch64) BIN_ARCH="arm64" ;;
    armv7l)  BIN_ARCH="arm" ;;
    *)
      echo -e "${RED}>> Unsupported architecture: $ARCH${NC}"
      return 1
      ;;
  esac

  local LATEST_URL
  LATEST_URL=$(curl -fsSL https://api.github.com/repos/DNSCrypt/dnscrypt-proxy/releases/latest \
    | grep "browser_download_url" \
    | grep "linux_${BIN_ARCH}" \
    | head -1 \
    | cut -d '"' -f4)

  if [ -z "$LATEST_URL" ]; then
    echo -e "${RED}>> Could not fetch download URL from GitHub.${NC}"
    return 1
  fi

  echo ">> Downloading: $LATEST_URL"
  local TMP_DIR
  TMP_DIR=$(mktemp -d)
  curl -fsSL "$LATEST_URL" -o "$TMP_DIR/dnscrypt.tar.gz"
  tar -xzf "$TMP_DIR/dnscrypt.tar.gz" -C "$TMP_DIR"

  local BIN_PATH
  BIN_PATH=$(find "$TMP_DIR" -name "dnscrypt-proxy" -type f | head -1)

  if [ -z "$BIN_PATH" ]; then
    echo -e "${RED}>> Binary not found in archive.${NC}"
    rm -rf "$TMP_DIR"
    return 1
  fi

  install -m 755 "$BIN_PATH" /usr/local/bin/dnscrypt-proxy
  rm -rf "$TMP_DIR"

  # Create systemd service
  cat > /etc/systemd/system/dnscrypt-proxy.service <<EOF
[Unit]
Description=DNSCrypt-proxy client
Documentation=https://github.com/DNSCrypt/dnscrypt-proxy
After=network.target

[Service]
ExecStart=/usr/local/bin/dnscrypt-proxy -config $DNSCRYPT_CONFIG
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  echo -e "${GREEN}>> dnscrypt-proxy installed via binary.${NC}"
  return 0
}

ensure_dnscrypt_installed() {
  if command -v dnscrypt-proxy >/dev/null 2>&1; then
    echo -e "${GREEN}>> dnscrypt-proxy is already installed.${NC}"
  else
    echo -e "${YELLOW}>> dnscrypt-proxy not found. Starting installation...${NC}"

    local installed=0

    install_via_apt && installed=1

    if [ "$installed" -eq 0 ]; then
      install_via_binary && installed=1
    fi

    if [ "$installed" -eq 0 ]; then
      echo -e "${RED}>> Installation failed via apt and binary.${NC}"
      echo -e "${YELLOW}>> Falling back to NATIONAL mode...${NC}"
      switch_national
      return 1
    fi
  fi

  # Always overwrite config — apt installs a broken default config
  write_default_config

  # Enable & start service
  systemctl enable dnscrypt-proxy >/dev/null 2>&1 || true
  systemctl start dnscrypt-proxy >/dev/null 2>&1 || true

  # Wait a moment and verify
  sleep 2
  if systemctl is-active --quiet dnscrypt-proxy; then
    echo -e "${GREEN}>> dnscrypt-proxy is running successfully.${NC}"
    return 0
  else
    echo -e "${RED}>> dnscrypt-proxy failed to start after install.${NC}"
    echo -e "${YELLOW}>> Falling back to NATIONAL mode...${NC}"
    switch_national
    return 1
  fi
}

########################################
# systemd-resolved helpers
########################################

RESOLVED_CONF_DIR="/etc/systemd/resolved.conf.d"
RESOLVED_CONF="$RESOLVED_CONF_DIR/dns-switch.conf"

resolved_use_dnscrypt() {
  # Point systemd-resolved to dnscrypt-proxy on 127.0.0.1:5053
  mkdir -p "$RESOLVED_CONF_DIR"
  cat > "$RESOLVED_CONF" <<EOF
[Resolve]
DNS=127.0.0.1:5053
DNSStubListener=no
EOF
  ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
  systemctl restart systemd-resolved >/dev/null 2>&1 || true
  echo ">> systemd-resolved → dnscrypt-proxy (127.0.0.1:5053)"
}

resolved_use_direct() {
  # Point systemd-resolved directly to given DNS servers
  local servers="$1"
  mkdir -p "$RESOLVED_CONF_DIR"
  cat > "$RESOLVED_CONF" <<EOF
[Resolve]
DNS=$servers
DNSStubListener=yes
EOF
  ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
  systemctl restart systemd-resolved >/dev/null 2>&1 || true
  echo ">> systemd-resolved → direct DNS ($servers)"
}

########################################
# Detect Current Mode
########################################

check_mode() {
  if systemctl is-active --quiet dnscrypt-proxy 2>/dev/null; then
    echo "FREE (DoH via dnscrypt-proxy)"
  else
    echo "NATIONAL (Auto-selected DNS)"
  fi
}

########################################
# FREE MODE
########################################

switch_free() {
  echo ">> Switching to FREE mode (DoH via dnscrypt-proxy)..."

  # Install dnscrypt if missing — fallback to national handled inside
  ensure_dnscrypt_installed || return

  systemctl start dnscrypt-proxy >/dev/null 2>&1 || true
  resolved_use_dnscrypt
  echo ">> dnscrypt-proxy status: $(systemctl is-active dnscrypt-proxy || true)"
}

########################################
# NATIONAL MODE (Auto-select best DNS)
########################################

select_best_dns() {
  echo ">> Testing DNS servers..."
  WORKING_DNS=()
  
  for DNS in "${IR_DNS_LIST[@]}"; do
    if dig @"$DNS" google.com +time=1 +short >/dev/null 2>&1; then
      echo -e "${GREEN}[OK]${NC} $DNS"
      WORKING_DNS+=("$DNS")
    else
      echo -e "${RED}[FAIL]${NC} $DNS"
    fi
    
    if [ "${#WORKING_DNS[@]}" -ge 2 ]; then
      break
    fi
  done
}

switch_national() {
  echo ">> Switching to NATIONAL mode (Auto DNS selection)..."
  systemctl stop dnscrypt-proxy >/dev/null 2>&1 || true

  select_best_dns

  if [ "${#WORKING_DNS[@]}" -eq 0 ]; then
    echo -e "${RED}No working DNS found!${NC}"
    return
  fi

  resolved_use_direct "${WORKING_DNS[*]}"
  echo ">> DNS set to: ${WORKING_DNS[*]}"
  echo ">> dnscrypt-proxy status: $(systemctl is-active dnscrypt-proxy || true)"
}

########################################
# AUTO MODE
########################################

auto_select() {
  echo ">> Auto-detecting best mode (robust check)..."

  # Make sure dnscrypt is installed before trying FREE mode
  ensure_dnscrypt_installed || return

  systemctl start dnscrypt-proxy >/dev/null 2>&1 || true
  resolved_use_dnscrypt

  echo ">> Warming up dnscrypt-proxy..."
  sleep 2

  local ok=0

  for i in 1 2 3; do
    echo ">> Test attempt $i..."
    if dig google.com >/dev/null 2>&1 && curl -fs --max-time 5 https://api.ipify.org >/dev/null 2>&1; then
      ok=1
      break
    fi
    sleep 1
  done

  if [ "$ok" -eq 1 ]; then
    echo ">> International connectivity detected (DNS + HTTPS OK)."
    echo ">> Staying in FREE mode."
  else
    echo ">> International connectivity seems DOWN after retries. Falling back to NATIONAL mode."
    switch_national
  fi
}

########################################
# STATUS
########################################

show_status() {
  echo "=============================="
  echo " Current DNS mode: $(check_mode)"
  echo "------------------------------"
  echo "/etc/resolv.conf:"
  cat /etc/resolv.conf
  echo "=============================="
}

########################################
# SAFE RESET
########################################

safe_reset() {
  echo ">> Safe reset: restarting DNS services and flushing caches..."
  systemctl restart dnscrypt-proxy >/dev/null 2>&1 || true
  if command -v resolvectl >/dev/null 2>&1; then
    resolvectl flush-caches || true
  fi
  echo ">> Done."
}

########################################
# TESTING
########################################

test_cmd() {
  local label="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    echo -e "${GREEN}[OK]${NC} $label"
    return 0
  else
    echo -e "${RED}[FAILED]${NC} $label"
    return 1
  fi
}

run_tests() {
  echo ">> Running DNS & connectivity tests..."
  local fails=0

  test_cmd "DNS resolve google.com" nslookup google.com || fails=$((fails+1))
  test_cmd "DNS resolve github.com" nslookup github.com || fails=$((fails+1))
  test_cmd "HTTP IP check (api.ipify.org)" curl -fs https://api.ipify.org || fails=$((fails+1))
  test_cmd "HTTP IP check (icanhazip.com)" curl -fs https://icanhazip.com || fails=$((fails+1))

  echo
  if [ "$fails" -eq 0 ]; then
    echo -e "${GREEN}All tests passed. Connectivity looks GOOD.${NC}"
  else
    echo -e "${RED}$fails test(s) failed. Connectivity has issues.${NC}"
  fi
}

########################################
# MENU LOOP
########################################

while true; do
  clear
  show_status
  echo
  echo "Choose an option:"
  echo "1) Switch to FREE mode (DoH)"
  echo "2) Switch to NATIONAL mode (Auto DNS select)"
  echo "3) Auto-select best mode"
  echo "4) Safe reset DNS services"
  echo "5) Run connectivity tests (with status)"
  echo "0) Exit"
  echo
  read -rp "Enter choice [0-5]: " choice
  echo

  case "$choice" in
    1) switch_free; pause ;;
    2) switch_national; pause ;;
    3) auto_select; pause ;;
    4) safe_reset; pause ;;
    5) run_tests; pause ;;
    0) echo "Bye."; exit 0 ;;
    *) echo "Invalid choice."; pause ;;
  esac
done
