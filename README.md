# NoelOps database backups

A copy of the whole NoelOps database is saved here every night:
`backups/YYYY-MM-DD.json` for each day, and `latest.json` for the newest one.
Backups older than 90 days are removed automatically.

## Restoring

1. Open the file you want (e.g. `backups/2026-09-30.json`), click **Download raw file**.
2. On the site, go to **Admin → Import State (JSON)** and pick that file.

Importing replaces the shared inventory, locations, timers, crew and settings for everyone.
Backups never contain the Discord webhook address or crew PINs (this repo is public);
restoring keeps the ones the site already has.
