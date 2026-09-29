#!/usr/bin/env bash
# Nightly backup of the NoelOps Firebase database.
#
# Downloads the whole shared database (inventory, locations, timers, crew,
# settings, activity, history) and commits it as backups/YYYY-MM-DD.json plus
# latest.json on the `backups` branch. Backups older than KEEP_DAYS are removed.
#
# Run by .github/workflows/nightly-backup.yml. Environment:
#   BACKUP_REMOTE  git URL to push the backups branch to (required)
#   DB_URL         database URL; defaults to the databaseURL in index.html
#   SITE_DIR       folder containing index.html (default: .)
#   KEEP_DAYS      how many days of backups to keep (default: 90)
#   BACKUP_DATE    override the date stamp, YYYY-MM-DD (for testing)
set -euo pipefail

SITE_DIR="${SITE_DIR:-.}"
KEEP_DAYS="${KEEP_DAYS:-90}"
BRANCH="backups"
TODAY="${BACKUP_DATE:-$(date -u +%F)}"
: "${BACKUP_REMOTE:?BACKUP_REMOTE is required}"

if [ -z "${DB_URL:-}" ]; then
  DB_URL=$(grep -oE 'databaseURL:[[:space:]]*"https?://[^"]+"' "$SITE_DIR/index.html" | head -n1 | sed -E 's/.*"(https?:[^"]+)".*/\1/')
fi
if [ -z "$DB_URL" ]; then
  echo "::error::No databaseURL found in index.html, so there is nothing to back up."
  exit 1
fi
DB_URL="${DB_URL%/}"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "Downloading $DB_URL/noelops.json"
curl -fsS --retry 3 --retry-delay 5 "$DB_URL/noelops.json" -o "$WORK/raw.json"

# Refuse to save an empty or broken download; drop who-was-online (it's not data)
python3 - "$WORK/raw.json" "$WORK/backup.json" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(src))
except ValueError as err:
    print(f"::error::The database returned something that isn't JSON: {err}")
    sys.exit(1)
if not isinstance(data, dict) or not data:
    print("::error::The database is empty. Not saving a backup, so older backups stay untouched.")
    sys.exit(1)
data.pop("presence", None)
missing = [key for key in ("stock", "locations") if key not in data]
if missing:
    print("::warning::This backup has no " + " or ".join(missing) + ". Check the site if that's unexpected.")
json.dump(data, open(dst, "w"), indent=2, sort_keys=True, ensure_ascii=False)
PY

# Check out the backups branch, or start it if this is the first run
if git clone --quiet --depth 1 --branch "$BRANCH" "$BACKUP_REMOTE" "$WORK/store" 2>/dev/null; then
  :
else
  git init --quiet -b "$BRANCH" "$WORK/store"
  git -C "$WORK/store" remote add origin "$BACKUP_REMOTE"
  cat > "$WORK/store/README.md" <<'MD'
# NoelOps database backups

A copy of the whole NoelOps database is saved here every night:
`backups/YYYY-MM-DD.json` for each day, and `latest.json` for the newest one.
Backups older than 90 days are removed automatically.

## Restoring

1. Open the file you want (e.g. `backups/2026-09-30.json`), click **Download raw file**.
2. On the site, go to **Admin → Import State (JSON)** and pick that file.

Importing replaces the shared inventory, locations, timers, crew and settings for everyone.
MD
fi

cd "$WORK/store"
mkdir -p backups
cp "$WORK/backup.json" "backups/$TODAY.json"
cp "$WORK/backup.json" latest.json

# Keep the last KEEP_DAYS days
CUTOFF=$(date -u -d "$TODAY - $KEEP_DAYS days" +%F)
for file in backups/*.json; do
  name=$(basename "$file" .json)
  if [[ "$name" < "$CUTOFF" ]]; then
    git rm --quiet "$file" 2>/dev/null || rm -f "$file"
    echo "Removed old backup $name"
  fi
done

git add -A
if git diff --cached --quiet; then
  echo "No changes since the last backup."
  exit 0
fi
git -c user.name="noelops-backup" -c user.email="noelops-backup@users.noreply.github.com" \
  commit --quiet -m "Backup $TODAY"
git push --quiet origin "$BRANCH"
echo "Saved backups/$TODAY.json"
