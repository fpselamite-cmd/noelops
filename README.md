# NoelOps Grow Dashboard

A single-page dashboard (`index.html`) for tracking strain inventory, coca stock, grow locations, pot plans and 36-hour grow timers, with Discord harvest alerts.

## Live sync (everyone sees updates in real time)

Out of the box, data is saved in each person's browser only (the header shows **Local Only**). To share one copy of the data between everyone, with changes showing up on every open page within about a second, connect a free Firebase Realtime Database:

1. Go to <https://console.firebase.google.com>, click **Create a project** and follow the steps (Google Analytics is not needed).
2. In the left menu, open **Build → Realtime Database** and click **Create Database**. Pick the location closest to your crew and choose **Start in locked mode**.
3. Open the database's **Rules** tab, replace everything with the rules below, and click **Publish**:

   ```json
   {
     "rules": {
       "noelops": {
         ".read": true,
         ".write": true
       }
     }
   }
   ```

4. Go to **Project settings** (the gear icon) → **General** → **Your apps**, click the **</>** (Web) icon, give it any nickname and click **Register app**. Firebase shows a `firebaseConfig` block. Copy it.
5. In `index.html`, find `const FIREBASE_CONFIG = null;` and replace `null` with the copied object, e.g.

   ```js
   const FIREBASE_CONFIG = {
       apiKey: "…",
       authDomain: "your-project.firebaseapp.com",
       databaseURL: "https://your-project-default-rtdb.firebaseio.com",
       projectId: "your-project",
       storageBucket: "your-project.appspot.com",
       messagingSenderId: "…",
       appId: "…"
   };
   ```

   Make sure the object includes `databaseURL`. If it's missing, copy the URL shown at the top of the Realtime Database page.

6. Commit the change. The header pill turns green and reads **Live Sync**.

The first browser to connect uploads its current data to the empty database, so open the site first on the device that has the most up-to-date numbers.

### What is shared and what isn't

| Shared with everyone | Stays in each browser |
|---|---|
| Strain inventory and coca count | Uploaded logo overrides |
| Grow locations, pot plans and timers | Selected planner tab |
| Discord webhook URL | Admin login |

- Timers use the database server's clock, so every device counts down the same.
- `+100` / `-100` style buttons are safe to press at the same moment from different devices; both presses count.
- Each finished harvest sends **one** Discord alert, even with many pages open.
- If someone loses connection, their changes are kept and sent when it comes back (the pill shows **Offline** meanwhile).

### About security

The rules above let anyone who has the site's link read and change the data, and the Firebase config in `index.html` is public. That's fine for a private crew tool, but anyone who finds the link could edit or wipe the numbers, so use **Admin → Export State** now and then to keep a backup.

## Hosting on GitHub Pages

1. In the GitHub repo, open **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to **Deploy from a branch**, choose **main** and **/ (root)**, then **Save**.
3. After a minute the site is live at `https://<your-username>.github.io/noelops/`. It updates automatically every time something is merged into `main`.

## Logos

- Header logo: `NoelOpsLogo.png`
- Strain logos: `logos/<strain id>.png` (see `logos/README.md`)
