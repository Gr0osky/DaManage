# DaManage – Password Manager

![Status](https://img.shields.io/badge/status-in_progress-blue)
![Platform](https://img.shields.io/badge/platform-Flutter%20%7C%20Node.js%20%7C%20MySQL-8A2BE2)
![Security](https://img.shields.io/badge/security-AES--256--GCM%20%7C%20JWT-success)

## Table of Contents

- [Architecture](#architecture)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
  - [Backend](#1-backend)
  - [Frontend (Flutter)](#2-frontend-flutter)
- [Features](#features)
- [Security Notes](#security-notes)
- [Project Structure](#project-structure)
- [API Overview](#api-overview)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)
- [Contributing](#contributing)

A cross-platform password manager built with a Flutter frontend and a Node.js/Express backend using MySQL. It supports user signup/login and encrypted storage of vault items.

## Architecture

- **Frontend**: Flutter app in `usdm_gui`
- **Backend**: Node.js/Express in `usdm-backend`
- **Database**: MySQL (`usdm_app`)
- **Auth**: JWT (issued on login)
- **Vault Security**: AES-256-GCM encryption at rest

## Requirements

- Node.js (v18+), npm
- MySQL 8+
- Flutter SDK (for desktop/mobile/web)

## Quick Start

### 1) Backend

1. Create database and tables
   - Create DB `usdm_app`
   - Import schema
     - Windows (PowerShell):
       - `mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS usdm_app CHARACTER SET utf8mb4;"`
       - `mysql -u root -p usdm_app < d:\\passManager\\DaManage\\usdm-backend\\schema.sql`
2. Configure environment
   - Copy `usdm-backend/.env.example` to `usdm-backend/.env`
   - Set variables:
     - `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
     - `JWT_SECRET` = long random string
     - `VAULT_KEY` = 32-byte Base64 key (e.g. `node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"`)
3. Install & run
   - In `usdm-backend`:
     - `npm install`
     - Dev: `npm run dev`
     - Prod: `npm start`
   - Backend runs at `http://localhost:3000`

### 2) Frontend (Flutter)

1. Install deps
   - In `usdm_gui`: `flutter pub get`
2. Run
   - Desktop/Web: `flutter run` (uses `http://localhost:3000`)
   - Android emulator: `flutter run` (auto-uses `http://10.0.2.2:3000`)
   - Override base URL if needed:
     - `flutter run --dart-define=API_BASE_URL=http://<HOST>:3000`
3. Android internet permission
   - Ensure `android/app/src/main/AndroidManifest.xml` includes:
     - `<uses-permission android:name="android.permission.INTERNET" />`

## Features

- User signup (`/signup`) and login (`/login`)
- JWT token issuance and auth middleware
- Vault CRUD endpoints (`/vault`): add, list, update, delete
- AES‑256‑GCM encryption for stored passwords
- Flutter UI: Home, Login, Signup, Vault list with add/delete and copy password

## Security Notes

- User passwords are stored as **bcrypt hashes** (one-way)
- Vault item passwords are stored as **ciphertext** (AES‑GCM) with a server key
- Keep `.env` secrets out of source control (see `.gitignore`)
- Use HTTPS in production; restrict CORS to trusted origins
- Consider client-side (zero-knowledge) encryption as a future enhancement

## Project Structure

```
DaManage/
├─ usdm-backend/           # Node/Express backend
│  ├─ server.js            # API and encryption
│  ├─ package.json         # Dependencies and scripts
│  ├─ schema.sql           # MySQL schema (users, vault_items)
│  └─ .env.example         # Env var template
├─ usdm_gui/               # Flutter frontend
│  ├─ lib/
│  │  ├─ screens/          # Home, Login, Signup, Vault
│  │  └─ services/         # ApiClient (JWT + API calls)
│  └─ pubspec.yaml
└─ .gitignore
```

## API Overview

- `POST /signup` → { message }
- `POST /login` → { message, token }
- `POST /vault` (auth) → { message }
- `GET /vault` (auth) → [ { id, title, username, url, password, notes, ... } ]
- `PUT /vault/:id` (auth) → { message }
- `DELETE /vault/:id` (auth) → { message }

## Troubleshooting

- 401 on vault routes → re-login to refresh token; verify `Authorization: Bearer <token>`
- Mobile cannot reach backend → use `10.0.2.2` (Android emulator) or your LAN IP via `--dart-define`
- DB connection errors → check `.env` values and that `usdm_app` exists with tables from `schema.sql`

## Roadmap

- Auth & Security
  - Optional client-side (zero-knowledge) encryption
  - Refresh tokens and token revocation
  - Rate limiting and IP-based throttling on auth routes
- Vault UX
  - Edit item dialog and fields validation
  - Password generator and password strength meter
  - Search, sort, and filters; pagination for large vaults
  - Import/Export (CSV/JSON) with safe handling
- Platform integrations
  - Biometric unlock (device secure enclave)
  - Desktop tray menu quick copy
- DevOps
  - Docker Compose (API + MySQL)
  - CI for lint/test; basic integration tests

## Contributing

1. Fork and clone the repo.
2. Create a feature branch from `main`.
3. For the backend:
   - Copy `usdm-backend/.env.example` to `.env` and set secrets.
   - Run `npm install` and `npm run dev`.
4. For the Flutter app:
   - Run `flutter pub get`.
   - `flutter run` (use `--dart-define=API_BASE_URL=...` as needed).
5. Add tests where reasonable. Keep secrets out of commits.
6. Open a pull request with a clear description and screenshots if UI changes.
