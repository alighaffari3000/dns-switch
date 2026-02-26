# dns-switch &nbsp;·&nbsp; [توضیحات فارسی](README.fa.md)

A Bash script to switch between **Free (DoH)** and **National** DNS modes on Linux servers — with automatic `dnscrypt-proxy` installation and configuration.

---

## Why DoH?

When you type a domain name like `google.com`, your device sends a DNS query to resolve it to an IP address. By default, this query travels in **plain text** — meaning your ISP, network admin, or anyone monitoring traffic can see every domain you visit, even if the page itself is HTTPS.

**DNS over HTTPS (DoH)** solves this by wrapping DNS queries inside encrypted HTTPS traffic. The result:

- 🔒 Your DNS queries are **encrypted** and indistinguishable from normal web traffic
- 🕵️ Your ISP **cannot log or monitor** which domains you're visiting
- 🚫 DNS-based censorship and filtering becomes much harder to enforce
- 🛡️ Protection against **DNS spoofing** and man-in-the-middle attacks

This is especially relevant on servers hosted in restricted network environments, where plain DNS queries are routinely intercepted or manipulated.

---

## Features

- 🔄 Switch between DoH (encrypted) and National DNS modes
- 📦 Auto-installs `dnscrypt-proxy` if not present (via `apt` or GitHub binary)
- ⚙️ Automatically configures `dnscrypt-proxy` and `systemd-resolved`
- 🧪 Auto-detects best mode based on connectivity
- 🌐 Tests international connectivity with fallback to National mode
- 🧹 Safe reset to restart DNS services and flush caches

---

## Requirements

- Linux (Ubuntu/Debian recommended)
- `systemd` + `systemd-resolved`
- `curl`, `dig`, `bash`
- Root access

---

## Installation

```bash
wget https://raw.githubusercontent.com/alighaffari3000/dns-switch/main/dns-switch.sh
chmod +x dns-switch.sh
sudo ./dns-switch.sh
```

---

## Usage

Run the script as root:

```bash
sudo ./dns-switch.sh
```

### Menu Options

| Option | Description |
|--------|-------------|
| `1` | Switch to **FREE mode** — DNS over HTTPS via dnscrypt-proxy |
| `2` | Switch to **NATIONAL mode** — Auto-selects best working national DNS |
| `3` | **Auto-select** — Tests connectivity and picks the best mode |
| `4` | **Safe reset** — Restarts DNS services and flushes cache |
| `5` | **Run tests** — Checks DNS resolution and HTTPS connectivity |
| `0` | Exit |

---

## How It Works

### FREE Mode (DoH)
1. Checks if `dnscrypt-proxy` is installed — installs it automatically if not
2. Writes a clean config with `cloudflare`, `google`, and `quad9-doh` as upstream resolvers
3. Disables systemd socket activation (fixes port conflict on apt-installed versions)
4. Configures `systemd-resolved` to forward DNS queries to `127.0.0.1:5053`

### NATIONAL Mode
1. Stops `dnscrypt-proxy`
2. Tests all DNS servers in the list and picks the first 2 that respond
3. Configures `systemd-resolved` to use them directly

### Auto Mode
1. Installs and starts `dnscrypt-proxy`
2. Runs 3 connectivity tests
3. Stays in FREE mode if international access works — otherwise falls back to NATIONAL

---

## dnscrypt-proxy Config (Default)

```toml
listen_addresses    = ['127.0.0.1:5053']
server_names        = ['cloudflare', 'google', 'quad9-doh']
fallback_resolvers  = ['8.8.8.8:53', '1.1.1.1:53']
ignore_system_dns   = true
```


