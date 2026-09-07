# Tokyo & Seoul Through My Eyes

A built, working site. Open **`index.html`** — double-clicking it is enough, no server needed.

Originals are untouched in `../Japan and korea trip/`. Nothing was deleted or moved.

## What is here

```
website/
  index.html              <- the page shell
  assets/css/styles.css   <- all styling
  assets/js/app.js        <- renders the page from the data; holds no content
  assets/photos/          <- 83 web copies, 1800px + 700px thumb, sorted by city/place
  data/
    places.json           <- ALL WORDS: sections, my writing, facts, links, recommendations
    photos.json           <- generated: path, size, alt, caption, EXIF time, GPS
    site-data.js          <- generated: the two JSON files bundled for file:// use
    captions.txt          <- source for alt text + captions
    photo-map.txt         <- original filename -> city / place / new name
    source-notes.txt      <- raw text from JK Project.pdf, unedited
  tools/                  <- rebuild scripts, see below
```

## Editing

**To change any words, edit `data/places.json`, then run the bundler.** That file is the whole
site: two cities, 23 places, in the order they appear on the page.

```bash
powershell -ExecutionPolicy Bypass -File tools\build-data.ps1
```

Full pipeline, only needed if you add or move photographs:

| Step | Script | What it does |
|---|---|---|
| 1 | `tools\resize-photos.ps1` | originals → `assets/photos/` (1800px + 700px, EXIF rotation applied) |
| 2 | `tools\build-photos.ps1` | → `data/photos.json` (adds pixel sizes, EXIF time, GPS) |
| 3 | `tools\build-data.ps1` | → `data/site-data.js` |

To add a photo: drop it in `../Japan and korea trip/`, add a line to `photo-map.txt`
(`filename|city|place|new-name`) and one to `captions.txt` (`filename|alt text|caption`),
then run all three. Rows whose source file is missing are skipped with a warning.

`tools/build-data.sh` is the same as step 3 for Git Bash.

## How the content is structured

Each place in `places.json` carries:

- **`myWords`** — my own writing, from the trip notes. Rendered as the main text. `\n\n` splits paragraphs.
- **`facts`** — researched background, *not* my writing. Rendered inside the collapsed
  **Learn more** panel so the two voices never blur together.
- **`learnMore`** — official-site links. All 21 were checked and return 200.
- **`recommendation`** — the "Try this" callout.
- **`aside`** — a nearby place from the notes with no photographs of its own. Two of these:
  Seiyoken inside Tokyo National Museum, the War Memorial of Korea inside the National Museum
  of Korea. They render as a secondary block, not their own section.
- **`dishes`** — only on *The Korean table*, rendered as a definition list.
- **`photoNote`** — only on NANTA, explaining that the photograph is promotional, not mine.

## What the page does

- Hero cross-fades five photographs; the program poster sits in the corner.
- Each city opens with **Where I was** — an SVG scatter of every geotagged photograph in that
  city, plotted from real EXIF coordinates. Hover to name the place, click to jump to it.
- Place sections have a sticky title column on wide screens.
- **Learn more** panels are collapsed by default so the page reads as a story first.
- Photo gallery: all 83, 26 filter chips (all / city / place), lazy-loaded thumbnails.
- Lightbox on every photograph, scoped to whichever group you clicked from — open one in the
  teamLab section and the arrows walk teamLab's six; open one in the gallery and they walk all 83.
  Arrow keys, Escape, focus is trapped and restored.

## Accessibility & robustness

- Real alt text on all 83 images, written for a screen reader.
- Every `<img>` carries width and height, so nothing shifts as images load.
- Scroll animations are progressive enhancement: content is visible by default, the hidden
  state only applies once JS confirms it can undo it, and everything force-reveals after 2.5s
  if the observer never fires. The page is never blank.
- `prefers-reduced-motion` disables the cross-fade, reveals, hover zooms and smooth scrolling.
- No external requests at all — no webfonts, no CDN, no analytics. It works offline and it will
  still work in ten years. To use a display font, change `--font-display` at the top of the CSS.
- Print stylesheet included.

## Still open

Four real video clips in the originals folder are unplaced — `275E6094…mp4`, `47AB72D9…mp4`,
`BCF10C75…mp4`, `IMG_1250.MP4`. The other 55 `.MOV` files are one-second Live Photo companions
to stills already on the site and can be ignored.
