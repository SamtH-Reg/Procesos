# AGENTS.md

## Cursor Cloud specific instructions

### Overview

This is a production control system for a fish processing plant (FRIOSUR SpA). It consists of:

| App | URL (dev) | Description |
|---|---|---|
| **Tablet** | `http://localhost:5500/index.html` | Touch-optimized SPA for plant floor workers |
| **Admin Console** | `http://localhost:5500/admin.html` | Desktop management dashboard |
| **Next.js Web** | `http://localhost:3000/` | Next.js 15 + Supabase SSR scaffold (in `web/`) |

The tablet and admin apps are **self-contained single-file SPAs** (no build step). The Next.js app lives in `web/` and uses npm.

### Running services

- **Static HTML apps**: `python3 -m http.server 5500` from repo root (serves `index.html` and `admin.html`)
- **Next.js dev server**: `cd web && npm run dev` (runs on port 3000)

### Lint / Test / Build

- **Lint**: `cd web && npx next lint` (ESLint for Next.js app; no linter for the HTML SPAs)
- **Build**: `cd web && npx next build` (note: there is a known TS strict-mode error in `middleware.ts` — the dev server still works)
- **Tests**: No automated test suite exists yet

### Backend (Supabase)

Both HTML apps require a Supabase cloud project for authentication and data sync. Without Supabase credentials, the apps show a login screen but cannot authenticate. They do operate in offline-first mode using `localStorage`.

The Next.js app needs `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in `web/.env.local`. The middleware gracefully handles missing credentials (warns and passes through).

### Key gotchas

- The HTML files are very large (`index.html` ~455K, `admin.html` ~199K) — all CSS/JS is inline.
- `node_modules/` is only in `web/` — the root has no `package.json`.
- No lockfile is committed; `npm install` generates `package-lock.json` from scratch.
- The `.cursor/rules/index-admin-parity.mdc` rule enforces that changes to one HTML file must be mirrored in the other.
