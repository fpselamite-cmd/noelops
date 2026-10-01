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
5. In `index.html`, find `window.NOELOPS_FIREBASE_CONFIG = {` (in its own block near the bottom of the file) and replace the `{ ... }` object with the one you copied. Paste **only the object**, not Firebase's `const firebaseConfig =` line:

   ```js
   window.NOELOPS_FIREBASE_CONFIG = {
       apiKey: "…",
       authDomain: "your-project.firebaseapp.com",
       databaseURL: "https://your-project-default-rtdb.firebaseio.com",
       projectId: "your-project",
       storageBucket: "your-project.appspot.com",
       messagingSenderId: "…",
       appId: "…"
   };
   ```

   Make sure the object includes `databaseURL`. If it's missing, copy the URL shown at the top of the Realtime Database page. If this block is ever pasted wrong, the rest of the site keeps working and the header pill just shows **Local Only**.

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

## Nightly backups

A GitHub Action (`.github/workflows/nightly-backup.yml`) copies the whole database every night at 07:17 UTC to the **`backups`** branch of this repo:

- `backups/YYYY-MM-DD.json`: one file per day, kept for 90 days
- `latest.json`: the newest backup

It needs no setup: it reads the database address from `index.html`. To run it right away, open the repo's **Actions** tab → **Nightly database backup** → **Run workflow**. If a run fails (for example the database is empty), GitHub emails the repo owner and the older backups are left untouched.

**To restore:** open the file you want on the `backups` branch, click **Download raw file**, then on the site go to **Admin → Import State (JSON)** and pick it. This replaces the shared inventory, locations, timers, crew and settings for everyone.

GitHub pauses scheduled workflows in repos with no activity for 60 days and emails you first; re-enable it from the Actions tab if that happens.

## Discord harvest message

**Admin → Discord** → **Discord Message** changes what the harvest alert says: bot name and picture, title, message, footer, side color, and whether the Postal / Pots / Ready At details are shown. Tags are filled in per harvest:

| Tag | Becomes |
|---|---|
| `{postal}` | Postal ID |
| `{alias}` | Location alias |
| `{duration}` | Timer length, e.g. `36h` |
| `{pots}` | Pot count |
| `{readyAt}` | Ready time in UTC |
| `{readyLocal}` | Ready time shown in each reader's own time zone |

The preview updates as you type, **Send Test** posts what's in the editor to your channel (even before saving), and **Reset to Default** brings back the original wording.

## Crew & permissions

In **Admin → Crew** you can add crew members, each with a name and a 4-8 digit PIN.

- Until the first crew member is added, anyone with the link can use everything.
- Once there's at least one, everyone signs in with their name and PIN, and stays signed in on that device until they sign out (from **My Profile**).
- Pick a role (Manager, Grower, Viewer) to start from, then tick exactly what each person can do: edit inventory, timers & harvests, grow planner. You can also limit which locations (and the Main Stash) they see.
- **The Admin page isn't a crew permission.** It only opens with the admin password, through the small **Admin** link at the bottom right of every page. The Admin tab appears in the menu only while it's unlocked; click **Lock admin** in the same spot (or Logout on the Admin page) to hide it again. Unlocking lasts until that browser tab is closed. Anyone who had the old Admin role is now a Manager.
- People with no permissions (Viewer) only see the dashboard stats: no locations, timers or activity.
- **New people can sign themselves up:** on the sign-in screen they type a new name and PIN (twice) and get a profile as a **Viewer**, marked **New · needs review**. Admins see a badge on the Admin page; click **Review**, pick a role and save. Turn this off with **Let new people create their own profile** on the Crew tab.
- Changing someone's PIN or removing them signs them out everywhere.
- The admin password also works on the sign-in screen as a master key.

This is a simple lock that stops casual misuse. Someone technical could still get around it, because the site has no server of its own.

## Grow Planner

Plan which strains go in each location's pots.

- **Location tabs** show how many pots are planned (amber = some unassigned, red = more planned than the location has) and whether it's growing.
- **The meter** shows the plan as a bar in each strain's color. **+N** on a strain card gives it all the unassigned pots; − / + change one pot at a time.
- **Smart Balance** fills the location's pots, giving the most to the strains you're lowest on. It counts bricks and bud in stock everywhere plus what the other locations are already planned to grow. **Even Split** spreads them evenly; **Clear** empties the plan.
- **All Locations** shows every location's plan side by side, with total pots and expected bricks per strain.
- **Estimates learn from real harvests.** They start at about 198 bud per pot. Whenever someone changes a number in the harvest form, that real amount per pot is saved for the strain, and estimates (and the next harvest form) use the average of its last 10 harvests. Each strain card shows where its number comes from. Admins can reset the learned yields from the link at the top of the page.

## My Profile

The button with your picture and name in the top right (or **My Profile** in the phone menu) opens your profile. It has three tabs.

**Account**
- **Picture:** upload any image. It's cropped to a square, shrunk, and shown everywhere your initials used to be (header, who's online, activity feed, crew list).
- **Name:** change the name you show up as. It has to be different from everyone else's on the crew.
- **PIN:** type your current PIN, then the new one twice. You stay signed in on that device; your other devices ask for the new PIN.

**Look**
- **Background color:** drag around the color wheel, use the slider, or tap a swatch. Only the page background changes.
- **Accent color:** recolors the green buttons, glows, progress bars and highlights. Strain logos and card colors stay the same.
- **Name color:** the color your name shows in for the crew, in Live Activity, pop-ups and as a ring around your picture.
- **Compact cards:** smaller strain cards and logos, so more fits on screen.
- **Reduce motion:** turns off the timer animations, pulsing and glows.

**Alerts** (when a grow you can see finishes)
- **Play a sound:** a short chime, with a volume slider and a **Test** button. Browsers only play sound after you've clicked somewhere on the page once.
- **Show a notification:** a pop-up from your browser, even when the tab is in the background. The browser asks for permission the first time. These name the postal, but only on your own device; the shared activity feed stays vague.
- Alerts work while the site is open in a tab. Grows that finished while it was closed don't alert when you come back.

For crew members, everything is saved to their profile and follows them to any device. Without crew sign-in (or when signed in with the admin password) it's saved on that device only, and there's no PIN to change. Admins editing someone in **Admin → Crew** keep that person's picture and settings. Everything except name color only changes what you see.

## Hosting on GitHub Pages

1. In the GitHub repo, open **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to **Deploy from a branch**, choose **main** and **/ (root)**, then **Save**.
3. After a minute the site is live at `https://<your-username>.github.io/noelops/`. It updates automatically every time something is merged into `main`.

## Logos

- Header logo: `NoelOpsLogo.png`
- Strain logos: `logos/<strain id>.png` (see `logos/README.md`)
