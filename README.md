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

   Make sure the object includes `databaseURL`. If it's missing, copy the URL shown at the top of the Realtime Database page. If this block is ever pasted wrong, the rest of the site keeps working and the footer pill just shows **Local Only**.

6. Commit the change. The sync pill in the footer (next to the clock) turns green and reads **Live Sync**.

The first browser to connect uploads its current data to the empty database, so open the site first on the device that has the most up-to-date numbers.

### What is shared and what isn't

| Shared with everyone | Stays in each browser |
|---|---|
| Strain inventory and coca count | Uploaded logo overrides |
| Grow locations, pot plans and timers, meth cooks | Selected Stash tab and Timers tab |
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

## Discord messages

**Admin → Discord** → **Discord Messages** has a **Grows | Meth cooks** switch. Grows send the grow message when they're ready to harvest; meth cooks send the meth message when their time is up (once per cook, even with many pages open). Both go to the same webhook. For each you can change the bot name and picture, title, message, footer, side color, and whether the details boxes are shown. Grow message tags are filled in per harvest:

| Tag | Becomes |
|---|---|
| `{postal}` | Postal ID |
| `{alias}` | Location alias |
| `{duration}` | Timer length, e.g. `36h` |
| `{pots}` | Pot count |
| `{readyAt}` | Ready time in US Eastern, e.g. `Fri, Oct 2, 3:14 PM ET` |
| `{readyLocal}` | Same as `{readyAt}` (kept so older messages still work) |

Meth cook message tags: `{size}` (High / Medium / Low), `{bags}`, `{who}` (who put it down), `{duration}` (cook time), `{readyAt}` and `{readyLocal}`.

The preview updates as you type, **Send Test** posts what's in the editor to your channel (even before saving), and **Reset to Default** brings back the original wording.

## Crew & permissions

In **Admin → Crew** you can add crew members, each with a name and a 4-8 digit PIN.

- Until the first crew member is added, anyone with the link can use everything.
- Once there's at least one, everyone signs in with their name and PIN, and stays signed in on that device until they sign out (from **My Profile**).
- Pick a role (Manager, Grower, Viewer) to start from, then tick exactly what each person can do: edit inventory, timers & harvests, pot plans, sales / bricks out and **Meth** (the Meth page and meth cook timers). Managers and Growers start with Meth on; untick it to hide meth from someone. You can also set their sales cut %. You can also limit which grow locations and stash houses they see.
- **The Admin page isn't a crew permission.** It only opens with the admin password, through the small **Admin** link at the bottom right of every page. There's no Admin button in the header: while it's unlocked, a glowing **Admin** button (with the new-signups count) shows next to that link at the bottom of every page, and the link turns into **Lock**; click **Lock** in the same spot (or Logout on the Admin page) to hide it again. Unlocking lasts until that browser tab is closed. Anyone who had the old Admin role is now a Manager.
- People with no permissions (Viewer) only see the dashboard stats: no locations, timers or activity.
- **New people can sign themselves up:** on the sign-in screen they type a new name and PIN (twice) and get a profile as a **Viewer**, marked **New · needs review**. Admins see a badge on the Admin page; click **Review**, pick a role and save. Turn this off with **Let new people create their own profile** on the Crew tab.
- Changing someone's PIN or removing them signs them out everywhere.
- The admin password also works on the sign-in screen as a master key.

This is a simple lock that stops casual misuse. Someone technical could still get around it, because the site has no server of its own.

## Day-to-day features

- **Who's online:** click the avatars in the header (or **Who's Online** in the phone menu) to see everyone online now, with their role and how long they've been on, plus the rest of the crew who are offline.
- **Your status:** in the same panel, pick **At the lab**, **Growing**, **Selling**, **On a run**, **Busy** or **AFK**, or type your own (up to 20 letters). It shows by your name in Who's online and on the Crew page, and clears when you close the site.
- **Live Activity** is a slim ticker under the timer bar on the dashboard. Click it (or the arrow) to open the full list.
- **Eastern time:** every clock and time on the site is US Eastern (ET), whatever your own time zone, and so are the Discord messages. Day totals, charts and the time-based titles go by the Eastern day too.
- **Undo:** most changes show a pop-up with an **Undo** button for about 8 seconds: stock changes, trimming, pressing, moving stock, logging bricks out, harvests, timer starts/stops and plan changes. Repeated presses on the same thing (+100, +100) merge into one Undo. Undo reverses just your change, so anything someone else changed in the meantime is kept.
- **Timers page → Grows:** a card per location with a growing plant, countdown, progress bar, ready time, pot plan and estimated bricks. Tick the boxes to **Start**, **Stop** or **Harvest** several grows at once (harvesting opens the harvest form for each in turn). **Start all idle** only starts grows that aren't running.
- **Upcoming harvests:** a timeline at the top of Timers → Grows shows when each grow is due and roughly how many bricks it should give, plus what's ready now. The dashboard's grow bar shows the next 24 hours' total.
- **Selling:** the truck button on anything in the **Stash**, or **Sell at the BlackMarket** on the **BlackMarket** page, records it being sold. It takes it out of the stash and adds it to the ledger (see **BlackMarket & budget** below).
- **Dashboard charts:** headline tiles for bricks on hand, bricks ready to press, everything that went out this week (split into weed, coke and meth) and bricks coming in over the next 24 hours; a **Made & Out** chart (made vs out per day, last 14 days, filterable to All, Weed, Coke or Meth) and **What's in Stock** (on hand + what can still be made, for every strain plus small/large coke bricks and meth bins). Hover a bar for details, or click **Table** to see the numbers.

## Stash houses and storage

- **Stash houses** hold bud, bricks, coke, meth and supplies. Add, rename or delete them in **Admin → Locations**. The built-in **Main Stash** can be renamed but not deleted. Deleting a stash house moves its stock to the Main Stash.
- **Grow ops don't store stock by default.** Each grow location has a **Stash house** its harvests go to, plus an **On-site storage** switch for the few that do keep stock. The harvest form has a **Send to** picker that starts on the grow op's stash house, or on site if it has storage. Each grow timer card shows where its harvest goes.
- A grow op without storage that still holds old stock shows a warning and a **Move everything to…** button (Undo works).
- **The Stash page has two rows of tabs:** **Stash houses** (gold, where stock is kept, with brick counts) and **Grows** (green, every grow with its pot plan count; a warehouse icon and brick count mean it keeps stock on site). The opened tab says which kind it is.
- **Leave out of totals:** any stash house or grow op can be left out of the totals. Its stock still shows on its own tab, but it doesn't count toward the dashboard, the All tab, the charts, the daily history or Smart Balance. Switch it on the place's Stash tab (anyone who can edit inventory), in the stash table, or in the grow location's Edit form. The All tab lists what isn't counted.
- In **Admin → Crew**, stash houses can be given or kept from each person like grow locations.

## Coke and meth

Each stash house (and grow op with storage) also tracks:

- **Coke Bricks:** only the coca leaves are counted. **Press small** or **Press large** takes the leaves and makes one brick:
  - Small brick: 2000 coca leaves (and bring 10 oil barrels, 40 cement bags, 25 battery acid).
  - Large brick: double that (4000 leaves, and 20 / 80 / 50).

  Oil, cement and acid aren't tracked; the card just reminds you what to bring. Change the recipe in **Admin → Products**. The card shows how many small and large bricks the leaves can make, with − / + and a truck button for each size.
- **Meth Bins:** a finished product, counted in bins, with − / + and a truck button.

Both can be moved between stashes (the leaves too), sold on the **BlackMarket** page (with their own default prices in Admin → Sales), and show on the dashboard next to the strains. Their logos are `logos/cokeSmall.png`, `logos/cokeLarge.png` and `logos/meth.png` (replaceable in Admin → Logos like the strain logos).

## BlackMarket & budget

The **BlackMarket** page (in the main menu, red and black) is where product sells for dirty money, usually from a Narco call:

- **Narco call:** the ringing red button at the top opens the sell form and tags the sale as a Narco call (shown in the ledger).

- **Totals:** today, last 7 days, last 30 days and all time, in bricks (and dollars when prices are entered).
- **Filters** by period, strain, person and location, with **By Strain** and **By Person** charts and the full log underneath. **Export CSV** downloads it as a spreadsheet.
- **Selling:** the **Sell at the BlackMarket** panel at the top walks through it: tap a big button for the strain (or Small / Large Coke Brick, or Meth Bin), pick where it comes from, set how many (− / +, or 1 / 2 / 5 / 10 / All), check who sold it and the price, and hit the big submit button. If an admin has set a default price, the price fills in by itself. The truck button on a Stash card jumps here with that item and location picked.

**Budget** (top of the BlackMarket page, admins only):

- The budget is **admin only** for now (behind the scenes): crew don't see cuts, earnings, payouts or the crew bank.
- Every sale is credited to the person who sold it, and they earn their **cut** of the price (a %). The default cut is set in **Admin → Sales**; give someone a different cut when editing them in **Admin → Crew**. Each sale keeps the cut it had at the time.
- **Crew bank** = all sales income, minus payouts and expenses. **Owed to crew** = what sellers have earned but haven't been paid yet.
- **Payouts by person** ranks sellers by what they earned, with sold / earned / paid / owed. Admins click **Pay** to record paying someone (it fills in what they're owed), or **Record Expense** for crew spending. Both can be undone or removed.
- Admins see each person's cut and what they're owed in the crew list.

**Who can use it:** the **Sell at the BlackMarket** permission on each person (Admin → Crew) controls the BlackMarket page and selling. Managers have it by default; Growers and Viewers don't. In **Admin → Sales** you can also set default prices, turn on **Only admins see prices**, export the log, or clear it.

## Pot Plan (Stash page)

Plan which strains go in each location's pots. Every grow has a tab on the **Stash** page (even grows with no on-site storage), and its pot plan sits under its stock.

- **Grow tabs** show how many pots are planned (amber = some unassigned, red = more planned than the location has).
- Anyone with the **Pot plans** or **Edit inventory** permission sees the Stash page. People with only Pot plans just see the grow tabs and their plans.
- **The meter** shows the plan as a bar in each strain's color. **+N** on a strain card gives it all the unassigned pots; − / + change one pot at a time.
- **Smart Balance** fills the location's pots, giving the most to the strains you're lowest on. It counts bricks and bud in stock everywhere plus what the other locations are already planned to grow. **Even Split** spreads them evenly; **Clear** empties the plan.
- The **All** tab on Stash shows every location's plan side by side, with total pots and expected bricks per strain.
- **Estimates learn from real harvests.** They start at about 198 bud per pot. Whenever someone changes a number in the harvest form, that real amount per pot is saved for the strain, and estimates (and the next harvest form) use the average of its last 10 harvests. Each strain card shows where its number comes from. Admins can reset the learned yields from the link above the plan.

## My Profile

The button with your picture and name in the top right (or **My Profile** in the phone menu) opens your profile. It has three tabs.

**Account**
- **My Stats:** how many grows you've harvested (only harvests with bud entered count, not a bare **Just Restart the Timer**), how much bud you brought in, and about how many bricks that makes. Your harvest count also shows next to your name in **Who's online** (and on the crew list for admins). Undoing a harvest takes it back off.
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

## Effects

Little touches that make the site feel alive:

- **Living plants:** the leaf on a growing timer sways; a ready grow pulses with a purple grow-light halo and the **Timers** badge pings. The beaker on the Timers button and on each meth cook bubbles, and fills up as the cook goes.
- **Celebrations:** leaves float up when you harvest, a brick stamps down when you press one, and a stamp (SENT by default) lands when you log something going out.
- **Smoke in the header**, **rolling numbers** (counts roll to their new number and flash when they change), **holo sticker cards** on the dashboard and **strain glow** when you hover a card.
- **Harvest ranks:** a badge next to names in Who's online, the crew list and My Profile. By default Seedling at 10 harvests, Grower at 50 and Kingpin at 100.
- **Friendly empty states** with a leaf drawing and a next step when there's nothing to show yet.

Admins set what's on for everyone, the stamp word and the rank names and harvest counts in **Admin → Effects**. Each person can turn effects off for themselves in **My Profile → Look → Effects**, and **Reduce motion** turns them all off.

## Crew page

The **Crew** page shows everyone in the crew as cards or a list (switch with **Cards / List**; your choice is remembered). Each person shows their role, harvest rank, whether they're online or when they were last active, harvests, bud brought in, how much they've logged going out and the last thing they did. Search by name, and sort by online, harvests, gone out, last active or name.

- Click anyone's name anywhere on the site (Who's online, Live Activity, the BlackMarket, pop-ups) to jump to them on the Crew page.
- **Their sales** opens the BlackMarket filtered to that person; **My Profile** is on your own card.
- Admins also see what each person can access, who's waiting for review, and an **Edit** button.
- **Leaderboards** (next to Cards and List): top 5 for harvests, bud brought in, bricks pressed, things gone out, moves, longest streak, most titles and rarest collection.
- Each card shows that person's top 3 titles; the **+N** opens their full profile.

**History (admins only):** **Admin → History** keeps the full story the Live Activity feed leaves out on purpose: who changed what, how much, where and when (the newest 500 actions). Search for a strain, postal or amount, or filter by person or kind of action. Undone actions stay in the list, crossed out. Note that this is hidden in the site only: like everything else, it's stored in the shared database.

**Menu and permissions:** each menu button only shows once someone has the permission for it: **Timers** needs timers, pot plans or Meth (each tab inside only shows if you have it), **Stash** needs inventory or pot plans, **Meth** needs Meth, **BlackMarket** needs the sell permission, **Crew** shows for every crew member, and Viewers only see the Dashboard. **Admin** only shows after the admin password is entered.

## Meth page

The **Meth** page is the crew's meth guide, built from Karma's Meth Guide (accurate as of 9/27/2026):

- **In the stash:** how many meth bins the crew has and where, with a link to the Stash. **Bins made** adds finished bins straight into the stash house you pick (with Undo).
- **What to grab:** pick a number of bins or bags and it works out the sodium, ammonia, hammers, baking soda, water and plastic bags, plus which yields to put down (high = 5, medium = 3, low = 1; 2 high yields make a bin).
- **Cooks down:** when you put a yield down, add it here or on **Timers → Meth cooks** with the time it takes (hours and minutes, whatever the game shows; it remembers your last one). Each cook gets a countdown card with a beaker that fills up: **Cooking**, then **Might be ready** once 75% of its time has passed, then **Ready**, which also sends the Discord meth message. **Edit** on a card changes its time left. Active cooks also show in the dashboard's timer bar (for people with Meth access). The Meth button shows how many are ready, and Live Activity says when one is. Press **Collected** to take it off. Admins see these in History.
- Meth shows up around the site too: a **Meth guide** link on the meth cards (Dashboard and Stash), cooks on profiles, a **Most meth cooks** leaderboard and four cook titles.
- **How it's made** (the 5 steps, including the 1 · 3 · 3 mix), **Rules in the lab**, and **Places** (the Lab at 10102, the Blue Container at 9359 and Sodium at 10101).

To update the guide text, edit the `tab-meth` section in `index.html`.

## Titles

124 titles to earn by doing things on the site: 96 you can see and work toward (harvests, bud, trimming, pressing, coke, coca leaves, meth bins and cooks, things going out, moving stock, starting grows and pot plans, streaks and odd hours, crew and profile) and 28 secret ones that nobody sees until someone in the crew finds one. Each title is a calling card in the style of old MW2 multiplayer titles, and its glow color is its rarity: Common, Uncommon, Rare, Epic, Legendary and Mythic (Legendary, Mythic and secret cards move).

- **Unlocking:** you get a "Title unlocked" pop-up, and Live Activity tells the crew. Harvest counts that were already tracked count, so people start with what they've earned. Time-based titles use US Eastern time. Click secrets need at least 50 clicks in a row with no other clicks in between.
- **My Profile → Titles:** wear one title (its card shows behind your name in Who's online and on the Crew page, and a small tag shows next to your name in Who's online and the Crew page), and pick up to 10 to show on your profile, or let it pick your 10 rarest. Locked titles show how to earn them.
- **Click anyone's name** anywhere on the site to see their profile: the card they're wearing, their stats and their titles as Discord-style badges (rarity dot, icon and name). Click a title to see how it was earned.
- **Admin → Titles:** give anyone a title (secret ones too) for a big RP moment, take one back, or turn titles off for everyone. The Seedling / Grower / Kingpin ranks are now harvest titles.

The secret titles live in the site's code, which is public on GitHub, so someone who reads the code could find them.

## Hosting on GitHub Pages

1. In the GitHub repo, open **Settings → Pages**.
2. Under **Build and deployment**, set **Source** to **Deploy from a branch**, choose **main** and **/ (root)**, then **Save**.
3. After a minute the site is live at `https://<your-username>.github.io/noelops/`. It updates automatically every time something is merged into `main`.

## Logos

- Header logo: `NoelOpsLogo.png` (the full-size original). The site shows `NoelOpsLogo-web.jpg`, a 480×320 copy that loads much faster; if you change the logo, replace both (or re-export the small one).
- Strain logos: `logos/<strain id>.png` (see `logos/README.md`)

## Change notes

Newest first. Every merge adds an entry here, written so it can be pasted straight into Discord.

### 🐢 Oct 2, 2026: Slower Live ticker
- The **Live Activity** ticker under the timer bar now drifts by slowly (about a third of the old speed) so it's easy to read

### 💀 Oct 2, 2026: BlackMarket, Live ticker, statuses and Eastern time
- **Log** is now the **BlackMarket**: red and black, product sells for **dirty money**, and a ringing **Narco call** button starts a sale and tags it in the ledger
- **Live Activity** is now a slim ticker under the timer bar; click it to open the full list. The stash cards use the whole width so they all fit on one screen
- Set a **status** in Who's online: At the lab, Growing, Selling, On a run, Busy, AFK or your own
- The **Stash** page splits its tabs into **Stash houses** and **Grows** so it's clear which is which
- Every clock and time on the site is now **US Eastern (ET)**, Discord messages too
- No more title tags next to names in Live Activity

### 🧭 Oct 2, 2026: Meth alerts, custom cook times and a cleaner header
- Meth cooks now send their own **Discord message** when ready. Edit it in **Admin → Discord** with the new **Grows | Meth cooks** switch
- Enter the **cook time** (hours and minutes) when you put a cook down, and fix it later with **Edit** on the card. It shows **Might be ready** at 75% of the time
- Active meth cooks show in the **dashboard timer bar** next to the grows
- New menu order: **Dashboard, Stash, Timers, Meth, Log, Crew**
- The **Admin** button moved to the bottom of the page (it glows there while unlocked)
- **Who's online** and your profile button are merged into one small pill in the top right

### ⚗️ Oct 2, 2026: Timers, meth cooks and pot plans on Stash
- **Grows** is now **Timers**, with a bubbling beaker icon. It has two tabs: **Grows** and **Meth cooks**
- Meth cooks get countdown cards like grows: the beaker fills up, turns **Might be ready** at 18h and **Ready** at 24h. Live Activity says when one is ready
- **Pot Plan** moved to the **Stash** page: every grow has a tab there, and its plan sits under its stock. The All tab shows every plan side by side
- **Bins made:** add finished meth bins straight into a stash house from the Meth page or Timers
- Meth cards on the Dashboard and Stash link to the **Meth** page. Cooks count on profiles, there's a **Most meth cooks** leaderboard and 4 new cook titles
- New **Meth** permission in each person's crew settings (on for Managers and Growers)
- Titles next to names are now small chips, and profiles show titles as Discord-style badges
- The meth guide credit now reads Karma

### 🧪 Oct 1, 2026: Meth page
- New **Meth** page in the menu with the whole Meth Guide: the 5 steps, the 1 · 3 · 3 mix, the rules in the lab and the postals
- **What to grab:** pick how many bins or bags and it tells you how much sodium, ammonia, baking soda, water, hammers and plastic bags you need
- **Cooks down:** add a yield when you put it down so the crew can see when it's ready. The Meth button shows how many are ready to collect
- Shows how many meth bins are in the stash

### 📊 Oct 1, 2026: Leaderboards and history
- **Leaderboards** on the Crew page: top growers, most pressed, most gone out, longest streak, rarest titles and more
- Crew cards now show everyone's top 3 titles
- Admins get a full **History** of who did what, where and when

### 🏆 Oct 1, 2026: Titles
- **120 titles** to unlock as calling cards, MW2 style: 92 to grind for and **28 secret ones** to find
- Rarity glows: Common, Uncommon, Rare, Epic, Legendary, Mythic
- Wear one in **My Profile → Titles** and pick up to 10 to show off
- Click anyone's name to see their profile and titles
- Time-based titles go by your own local time. Happy hunting 👀

### 👥 Oct 1, 2026: Crew page
- New **Crew** page: everyone as cards or a list, with who's online, harvests, bud, what's gone out and the last thing they did
- Click any name on the site to jump to that person
- The **Grows** badge now only shows (and pings) the number of grows ready to harvest
- Menu buttons only show once you have permission for that page, and **Admin** only shows for the admin

### ✨ Oct 1, 2026: Effects
- Grow timers come alive: leaves sway, ready grows pulse purple and the **Grows** badge pings
- Leaves burst when you harvest, a brick stamps down when you press, and a **SENT** stamp lands when something goes out
- Smoke drifts through the header, numbers roll when they change, and dashboard cards get a holo foil shine and glow in their strain color
- **Harvest ranks** next to your name: Seedling, Grower, Kingpin
- Admins can tweak all of it in **Admin → Effects**, and you can turn any of it off in **My Profile → Look**

### 💜 Oct 1, 2026: Grow Light look
- New header: purple grow-light glow with a neon green underline on the page you're on
- Main buttons glow green, secondary buttons glow purple
- Page titles get an icon and a little weed-leaf underline
- Faint weed-leaf pattern in the background
- The **Grows** icon and the plant on every grow timer are now a weed leaf that grows as the timer runs

### 🧹 Oct 1, 2026: Simpler and easier to read
- The menu is now just **Dashboard**, **Grows**, **Stash** and **Log**. The pot plan lives under **Grows** (Timers / Pot Plan tabs)
- Coke only counts **coca leaves** now. Pressing takes the leaves, and the card reminds you what oil, cement and acid to bring
- Plainer wording everywhere: **Ready to press** instead of "potential", **Ready!** / **Growing** / **Not started** on grows, **Log Something Going Out** for sales
- Harvests only count on your profile when bud is entered

### 🌱 Oct 1, 2026: Harvest counts on profiles
- **My Profile** now has **My Stats**: how many grows you've harvested, total bud and about how many bricks that makes
- Everyone's harvest count shows next to their name in **Who's online**
- Seller cuts, earnings and the budget are admin only for now

### 🏠 Oct 1, 2026: Stash houses
- Add stash houses in **Admin → Locations**. Most grow ops don't hold stock anymore, so harvests go straight to their stash house (pick where in the harvest form)
- Grow ops that do keep stock can switch on **On-site storage**
- Any stash or grow op can be **left out of the totals**. Its stock still shows on its own tab
- Fixed the Meth Bin logo still showing the old picture
- Deleting a grow location now moves its coke, meth and supplies too, not just bud

### 🌿 Sept 30 – Oct 1, 2026: Big update
**❄️ Coke & Meth**
- New **Meth Bins** and **Coke Bricks** (small + large) cards with the new sticker logos
- Pressing coke uses leaves, oil, cement and battery acid (small: 2000 / 10 / 40 / 25, large: double). The card shows what you can make or what you're short on

**🚚 Sales & Budget**
- New **Sales** page: tap a product, pick where it's from, how many and who sold it, then submit
- Crew bank with seller cuts, payouts and expenses. Earnings show on profiles

**📊 Dashboard**
- New charts: **Made & Out** (filter weed / coke / meth), **Stock by Product**, and what went out this week
- Click the avatars up top to see who's online
- Live Sync + clock moved to the footer

**⏱️ Growing**
- New **Grow Timers** page with an upcoming harvests timeline and bulk start / stop / harvest
- Grow Planner rework: Smart Balance, yields learned from real harvests, and an All Locations view

**👤 Profiles**
- Sign yourself up, then set your picture, PIN, colors and harvest alerts in **My Profile**

**✨ Other**
- **Undo** button on most changes
- Times show in your own time zone
- Inventory reworked around bricks and potential bricks
