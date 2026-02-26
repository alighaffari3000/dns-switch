# dns-switch

A Bash script to switch between **Free (DoH)** and **National** DNS modes on Linux servers — with automatic `dnscrypt-proxy` installation and configuration.

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

---

## License

MIT

---
---

<div dir="rtl">

# dns-switch

اسکریپت Bash برای سوئیچ بین حالت **آزاد (DoH)** و **ملی** در سرورهای لینوکسی — با نصب و کانفیگ خودکار `dnscrypt-proxy`.

---

## امکانات

- 🔄 سوئیچ بین DNS رمزنگاری‌شده (DoH) و DNS ملی
- 📦 نصب خودکار `dnscrypt-proxy` در صورت نبود (از طریق `apt` یا باینری GitHub)
- ⚙️ کانفیگ خودکار `dnscrypt-proxy` و `systemd-resolved`
- 🧪 تشخیص خودکار بهترین حالت بر اساس دسترسی به اینترنت
- 🌐 تست اتصال بین‌المللی با فال‌بک به حالت ملی
- 🧹 ریست امن برای راه‌اندازی مجدد سرویس‌های DNS و پاک کردن کش

---

## پیش‌نیازها

- لینوکس (ترجیحاً Ubuntu یا Debian)
- `systemd` و `systemd-resolved`
- ابزارهای `curl`، `dig`، `bash`
- دسترسی root

---

## نصب

```bash
wget https://raw.githubusercontent.com/alighaffari3000/dns-switch/main/dns-switch.sh
chmod +x dns-switch.sh
sudo ./dns-switch.sh
```

---

## نحوه استفاده

اسکریپت را با دسترسی root اجرا کنید:

```bash
sudo ./dns-switch.sh
```

### گزینه‌های منو

| گزینه | توضیح |
|-------|-------|
| `1` | حالت **آزاد** — DNS over HTTPS از طریق dnscrypt-proxy |
| `2` | حالت **ملی** — انتخاب خودکار بهترین DNS ملی |
| `3` | **انتخاب خودکار** — تست اتصال و انتخاب بهترین حالت |
| `4` | **ریست امن** — راه‌اندازی مجدد سرویس‌ها و پاک‌سازی کش |
| `5` | **اجرای تست** — بررسی DNS و اتصال HTTPS |
| `0` | خروج |

---

## نحوه عملکرد

### حالت آزاد (DoH)
۱. بررسی نصب بودن `dnscrypt-proxy` — در صورت نبود، نصب خودکار انجام می‌شود
۲. نوشتن کانفیگ با سرورهای `cloudflare`، `google` و `quad9-doh`
۳. غیرفعال کردن socket activation سیستمی (رفع تداخل پورت در نسخه apt)
۴. کانفیگ `systemd-resolved` برای ارسال درخواست‌ها به `127.0.0.1:5053`

### حالت ملی
۱. متوقف کردن `dnscrypt-proxy`
۲. تست تمام DNS سرورهای لیست و انتخاب ۲ سرور اول که پاسخ می‌دهند
۳. کانفیگ `systemd-resolved` برای استفاده مستقیم از آن‌ها

### حالت خودکار
۱. نصب و راه‌اندازی `dnscrypt-proxy`
۲. اجرای ۳ بار تست اتصال
۳. ماندن در حالت آزاد در صورت موفقیت — در غیر این صورت رفتن به حالت ملی

---

## کانفیگ پیش‌فرض dnscrypt-proxy

```toml
listen_addresses    = ['127.0.0.1:5053']
server_names        = ['cloudflare', 'google', 'quad9-doh']
fallback_resolvers  = ['8.8.8.8:53', '1.1.1.1:53']
ignore_system_dns   = true
```

---


</div>
