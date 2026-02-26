# 🌐 DNS-switch &nbsp;·&nbsp; [فارسی](README.fa.md)

**dns-switch** is a fast, smart Bash script designed to help Linux servers bypass internet restrictions, censorship, and DNS manipulations. It allows you to seamlessly switch between **Free Mode (Encrypted DNS)** and **National Mode (Local/Internal DNS)**.

When you're dealing with restricted networks where plain DNS requests are intercepted or spoofed, this script is your server's lifesaver!

---

## 🧐 Why do we need this script?

In many restricted internet environments, the default DNS queries your device sends to resolve domain names (like `google.com`) are transmitted in **plain text**. This means:
- Your ISP or network administrator can see every site you visit.
- **DNS Spoofing/Poisoning:** Networks can intercept your request and return a fake IP address, effectively blocking access to the real website or redirecting you to a block page.

This script provides two main solutions:
1. **Using DoH (DNS over HTTPS)** to encrypt your requests, making them unreadable and unalterable by the network.
2. **Fast switching to National/Local DNS** when international internet access is fully disconnected, ensuring your server remains reachable within the local intranet.

---

## 🛡️ What is DNS over HTTPS (DoH)?

To put it simply:
- **Normal DNS** is like sending a postcard. The mail carrier (ISP) and anyone along the route can read the destination and the message, or even change it!
- **DNS over HTTPS (DoH)** is like placing that message inside a locked, encrypted safe. Your request is sent over a secure HTTPS connection.

**Benefits of DoH in this script:**
- 🔒 Your DNS queries are completely **encrypted** and indistinguishable from regular web traffic.
- 🕵️ Your ISP **cannot log or monitor** which domains you are querying.
- 🚫 It easily bypasses DNS-based censorship and filtering.
- 🛡️ Protects against Man-in-the-Middle (MitM) attacks and DNS spoofing.

---

## 🚀 Key Features

- 🔄 **One-Click Switch:** Instantly toggle between global (encrypted) and national (local) network modes.
- 🤖 **Smart & Automated (Auto Mode):** Tests your connection and automatically picks the most reliable mode for your server.
- 📦 **Zero-Hassle `dnscrypt-proxy` Setup:** If you don't have the encryption tool installed, the script downloads, installs, and configures it automatically (via `apt` or GitHub binary).
- ⚙️ **System Configuration:** Automatically handles all the complex `systemd-resolved` settings without your intervention.
- 🧹 **Safe Reset:** Easily flush DNS caches and restart services to fix sudden network glitches.

---

## 🛠️ Prerequisites

To run this tool, you need:
- A Linux operating system (preferably **Ubuntu** or **Debian**)
- `systemd` and `systemd-resolved` enabled (default on most modern distros)
- Basic tools installed: `curl`, `dig`, `bash`
- **Root** privileges (or a user with `sudo` permissions)

---

## 📥 Installation & Usage

Just run the following commands in your server's terminal:

```bash
wget https://raw.githubusercontent.com/alighaffari3000/dns-switch/main/dns-switch.sh
chmod +x dns-switch.sh
sudo ./dns-switch.sh
```

---

## 🎮 Menu Guide

Upon running the script with root access, you'll see a menu with the following options:

| Option | Name | Description & Use Case |
|--------|------|------------------------|
| `1` | **FREE Mode (DoH)** | Encrypts all your server's DNS requests. Use this for unrestricted access to global services (GitHub, Docker, Google, etc.). |
| `2` | **NATIONAL Mode** | The script automatically tests a list of internal/national DNS servers and connects to the fastest ones responding. Perfect for when international internet is down. |
| `3` | **AUTO Mode** | The script tests the internet itself. If the global web is reachable, it activates Free Mode. If not, it falls back to National Mode. |
| `4` | **Safe Reset** | Restarts network settings and flushes the DNS cache. Always try this first if a site isn't loading! |
| `5` | **Run Tests** | Checks the server's connection to the global internet and tests DNS performance, giving you a health report. |
| `0` | **Exit** | Closes the script. |

---

## ⚙️ How It Works Under the Hood

- **In FREE Mode (DoH):**
  The script configures `dnscrypt-proxy` to use trusted upstream resolvers (like Cloudflare, Google, and Quad9). It disables conflicting systemd socket activations and forces `systemd-resolved` to forward queries to locally hosted proxy on `127.0.0.1:5053`.

- **In NATIONAL Mode:**
  The script gracefully stops `dnscrypt-proxy` and pings a comprehensive list of internal DNS servers. It picks the first two servers that respond successfully and applies them directly to `systemd-resolved` and `/etc/resolv.conf`.

---

## 📝 Default dnscrypt-proxy Configuration

If you're curious, the script applies the following robust configuration to bypass restrictions during installation:

```toml
listen_addresses    = ['127.0.0.1:5053']
server_names        = ['cloudflare', 'google', 'quad9-doh']
fallback_resolvers  = ['8.8.8.8:53', '1.1.1.1:53']
ignore_system_dns   = true
```

