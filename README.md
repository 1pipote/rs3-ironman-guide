# IronMan Guide 2027 — checklist site

This repository is a small website: a step-by-step RuneScape 3 Ironman route with checkboxes.
It is served by GitHub Pages (Settings → Pages), so it updates itself about a minute after
anything here changes.

- `index.html` — the page (checklist, editor, everything). Rarely needs to change.
- `guide.txt` — the guide itself, in plain text. This is the file people change.

## Proposing a change

Anyone can suggest improvements without knowing anything about code:

1. On the site, hover a step and click ✎ (or menu ⋯ → Edit guide…). Edit the text.
2. Click **Propose changes**. A panel walks you through three steps: copy the text, open
   `guide.txt` on GitHub, paste and click *Propose changes* → *Create pull request*.
3. The owner reviews the pull request and merges it. The site updates by itself.

Checkmarks are stored in each person's own browser and are never sent anywhere.

## Format of guide.txt

```
# Bank 12                     a new section
- Withdraw: 25 pure essence   a step with a checkbox
  - sub-step                  two spaces in front = sub-step
* a note                      a note without a checkbox
```

Emoji are typed as-is: 🟡 accepted · ✅ completed · 📍 teleport · ⏸️ pause · 🏅 task set done ·
⚙️ repeatable · 🔴 warning · 📖 write it down · 🕒 daily.
`[Lumbridge Easy Task]` shows as a tag. `[[Quest Name]]` links to the RuneScape Wiki (well-known
quest names link on their own). `==text==` highlights (`==g:text==` green, `==r:text==` red).
A line with no marker continues the step above it.
