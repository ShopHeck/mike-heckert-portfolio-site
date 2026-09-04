# Site Audit — michaelheckert.com

Audit of `index.html` (single-file static site) as of commit `4685079`.

Every number below was measured directly from the repository files. Where a claim
is inference rather than measurement, it is labelled.

---

## How this was measured

| Check | Method |
|---|---|
| Payload | `os.path.getsize` over every `<img src>` + `index.html` |
| Image dimensions | JPEG/PNG header parse + `identify` |
| Markup quality | `grep` counts over `index.html` for `width=`, `loading=`, `srcset`, `<main`, etc. |
| Contrast | WCAG 2.1 relative-luminance ratio computed from the `:root` tokens |
| Font payload | Fetched the live Google Fonts CSS for the exact query used and counted `@font-face` rules + unique latin `woff2` URLs |
| Broken links | Served the repo on `:4173` and requested every local `href`/`src` — **16/16 returned 200** |
| Compression savings | Real `convert` runs (ImageMagick 6.9, `libwebp 1.2.4` + AVIF) over all 13 rasters, at original and slot-correct sizes |
| Claim re-check | Every number in this document re-asserted against the repo in a single verification script — **33/33 matched** |

---

## Scorecard

| Area | Grade | One-line reason |
|---|---|---|
| **Site performance** | **D** | 3.94 MB first load; measured to 0.55 MB with format + `srcset` alone |
| **SEO** | **C+** | Strong meta/OG/JSON-LD, but no `robots.txt`, no sitemap, no FAQ markup |
| **CRO** | **C** | Three overlapping sponsorship sections dilute one clear next step; no analytics |
| **Layout / UX** | **B−** | Polished desktop design; mobile loses all section navigation |
| **Accessibility** | **C+** | Good focus/reduced-motion handling; no `<main>`, no skip link, contrast fail |

---

## Implementation status

Items 1–8 (P0), 10–15 (P1) and 17, 18, 20, 21 (P2) are **implemented** in this
branch. Measured result: **3.94 MB → 0.83 MB desktop (−79%)** / **0.70 MB mobile @2x
(−82%)**, over 21 HTTP/2 requests instead of 16.

| # | Item | Status |
|---|---|---|
| 1 | WebP/AVIF + `srcset`/`sizes` | ✅ 74 variants in `assets/gen/`, `npm run images` to regenerate |
| 2 | `loading="lazy" decoding="async"` | ✅ on all 19 below-fold images |
| 3 | Hero `preload` + `fetchpriority` | ✅ |
| 4 | Drop JetBrains Mono | ✅ system mono stack; 2 families requested, was 3 |
| 5 | Non-blocking font CSS | ✅ `media="print"` swap + `<noscript>` fallback |
| 6 | Mobile nav drawer | ✅ toggle, `aria-expanded`, Escape-to-close, closes on navigate |
| 7 | `<main>` + skip link + aria roles | ✅ 0 role-less `aria-label` divs remain |
| 8 | `--progress` contrast | ✅ `#855D00` = **5.25:1** (was 4.18) |
| 9 | Merge §§4–6 sponsorship sections | ⬜ **not done** — editorial call, needs sign-off |
| 10 | CTA label/destination mismatch | ✅ now downloads the PDF |
| 11 | Analytics + CTA events | ✅ 19 `data-track` CTAs (all verified as real DOM attributes); set `ANALYTICS.provider` to go live |
| 12 | `robots.txt` + `sitemap.xml` | ✅ added and in the build script |
| 13 | `FAQPage` JSON-LD | ✅ all 5 FAQs, text extracted from the page |
| 14 | Shorten title | ✅ **55 chars** (was 67) |
| 15 | Untrack `dist/`, delete duplicate | ✅ `portfolio-3.html` + 2 unused assets removed |
| 16 | Replace `mailto:` with a form | ⬜ needs a form backend + credentials |
| 17 | Move reaction game | ✅ now below the sponsor CTA |
| 18 | `SportsEvent`/`Organization` data | ✅ + `ProfilePage` |
| 19 | Unique imagery for reused slots | ⬜ needs new photography |
| 20 | Orphaned `.pptx` / unused assets | ✅ linked as "editable PPTX"; 2 dead assets deleted |
| 21 | Remove `--gold`, scope tilt | ✅ tilt limited to above-fold cards |
| 22 | A/B test price anchoring | ⬜ blocked on #11 going live |

**Verification run:** `npm run build` succeeds; a local server returned **HTTP 200 for
all 91 referenced local URLs** (including every `srcset` candidate); the HTML parses
with no unclosed or mismatched tags and no duplicate `id`s; the inline script passes
`node --check`; all 3 JSON-LD blocks parse.

The Cloudflare Pages preview was also checked live, which caught a bug the local
checks missed: two `data-track` injections had landed inside the anchor's *text
content* rather than the tag, rendering `data-track="mailto-open" data-source=...>`
as visible copy on the Deal Room and Sponsor HQ CTAs. Both are repaired, and all 19
are now verified by parsing the DOM for real attributes rather than counting
substring occurrences.

---


# 1. Performance — the biggest problem

**First-visit payload (before): 3.94 MB across 16 requests.** HTML is 94.1 KB (24.5 KB gzipped) — that part is fine. The images are 3.85 MB of it.

```
index.html                                    94.1 KB
assets/media-fight-night-key-art.jpg         759.9 KB   1440x1800
assets/media-cfn-walkout.jpg                 506.3 KB   1200x1800
assets/fight-clearwater-victory.jpg          492.9 KB   1800x1200
assets/media-king-killer-arena.jpg           388.0 KB   1200x1800  <- LCP
assets/media-sponsor-shirt.jpg               302.4 KB   1200x1800
assets/sponsor-vitality-wellness.png         269.8 KB    900x900
assets/fight-clearwater-punch.jpg            269.2 KB   1050x1400
assets/media-king-killers-portrait.jpg       258.6 KB   1200x1800
assets/fight-clearwater-raised-hand.jpg      221.2 KB   1120x1400
assets/fight-clearwater-walkout.jpg          210.5 KB   1245x1400
assets/sponsor-1tom-plumber.png              127.7 KB    900x900
assets/sponsor-ufc-gym.png                    75.9 KB    900x539
assets/sponsor-bluefitmd.png                  57.2 KB    900x900
assets/project-*.svg                           1.8 KB   (2 files)
```

### 1.1 Nothing is lazy-loaded — verified `0` occurrences of `loading=`

All 20 `<img>` tags load eagerly. The sponsor-logo wall, the proof library and the
project thumbnails are 3,000+ pixels below the fold, yet they compete for bandwidth
with the LCP hero image on first paint.

**Fix:** add `loading="lazy" decoding="async"` to the 19 below-fold images, and
`fetchpriority="high"` to the hero.

### 1.2 No responsive images — verified `0` occurrences of `srcset`

A 390 px-wide phone downloads the same 1440×1800 / 1800×1200 files as a 4K display.

**Worst offender:** `media-fight-night-key-art.jpg` is **760 KB at 1440×1800
(2.59 MP)** and renders inside `.proof-card`, which is `min-height:150px` (line 263).
Working the grid geometry (`.wrap` 1120 − 48 padding = 1072 px content;
`.proof-library` is `1.15fr / .85fr` with an 18 px gap, line 261) that card is
**448 × 150 CSS px** — so at 2× DPR it needs 0.27 MP. **The source is 9.7× more
pixels than the slot can display.**

| Proof-library image | Source | Renders | Needs @2× | Overkill |
|---|---|---|---|---|
| `media-fight-night-key-art.jpg` | 1440×1800 (2.59 MP) | 448×150 | 895×300 (0.27 MP) | **9.7×** |
| `media-cfn-walkout.jpg` | 1200×1800 (2.16 MP) | 448×150 | 895×300 (0.27 MP) | **8.0×** |
| `media-sponsor-shirt.jpg` | 1200×1800 (2.16 MP) | 606×320 | 1212×640 (0.78 MP) | 2.8× |

Those three alone are **1.53 MB**. Measured after right-sizing + WebP q80: **125.4 KB
(−92%)**.

**Fix:** `srcset` + `sizes` at ~640/960/1280 px widths.

### 1.3 No modern formats — measured savings

Every raster asset is JPEG or PNG. I converted **all 13** with ImageMagick's real
`libwebp 1.2.4` / AVIF encoders to measure actual savings rather than quote a rule of
thumb.

**Format only, original resolution:**

| | Total | vs. current |
|---|---|---|
| Current (JPEG/PNG) | 3,939.8 KB | — |
| WebP q80 | 1,380.0 KB | **−65%** |
| AVIF q60 | 1,032.0 KB | **−74%** |

Per-file WebP q80 savings ranged 57%–78% on the photos and 66%–78% on the logo PNGs.

**Format + right-sized to the actual CSS slot** (2× DPR, `object-fit` respected) —
this is what a correct `srcset` would serve a desktop visitor:

| File | Now | Optimised | Saving |
|---|---|---|---|
| `media-fight-night-key-art.jpg` | 759.9 K | 40.0 K | **−95%** |
| `media-cfn-walkout.jpg` | 506.3 K | 38.4 K | **−92%** |
| `fight-clearwater-victory.jpg` | 492.9 K | 114.1 K | −77% |
| `media-king-killer-arena.jpg` (LCP) | 388.0 K | 81.0 K | −79% |
| `media-sponsor-shirt.jpg` | 302.4 K | 47.0 K | −84% |
| `fight-clearwater-punch.jpg` | 269.2 K | 58.5 K | −78% |
| `media-king-killers-portrait.jpg` | 258.6 K | 22.1 K | −91% |
| `fight-clearwater-raised-hand.jpg` | 221.2 K | 30.1 K | −86% |
| `fight-clearwater-walkout.jpg` | 210.5 K | 21.7 K | −90% |
| **4 sponsor logo PNGs** | **530.6 K** | **12.1 K** | **−98%** |

> **The logo wall is the single most wasteful block on the page.** Four PNGs at
> 900×900 (one at 900×539) are served at 530.6 KB to render at `max-height:54px`
> inside `.logo-slot` (line 312). At 2× DPR they need ~108×108 px. That is **12.1 KB
> of work being done by 530.6 KB.**

**Measured bottom line: 3.94 MB → 0.55 MB total first-visit payload (−86%).**
A mobile visitor on the 1× variants would get roughly half of that again.

### 1.4 LCP image is not prioritised

The hero image `media-king-killer-arena.jpg` (388 KB) is the LCP candidate but has no
`<link rel="preload">` and no `fetchpriority`. It is discovered only after the HTML
parses and after the render-blocking font stylesheet resolves.

**Fix:**
```html
<link rel="preload" as="image" href="assets/hero-800.webp"
      imagesrcset="hero-600.webp 600w, hero-900.webp 900w" fetchpriority="high">
```

### 1.5 Render-blocking font stylesheet

The Google Fonts `<link>` in `<head>` is render-blocking. I fetched the exact CSS the
site requests: it returns **27 `@font-face` rules**, but because all three families are
variable, only **3 unique latin `woff2` files** are actually downloaded:

- Bricolage Grotesque latin — one file serves the requested 400/600/800
- JetBrains Mono latin — one file serves 400/600
- Schibsted Grotesk latin — one file serves 400/500/700

So the byte weight is reasonable; the problem is that the **request sits on the
critical path and blocks first paint**.

**Two fixes, in order of value:**
1. **Drop JetBrains Mono.** It is used only for small uppercase labels and numbers
   (`.kicker`, `.kpi`, `.tag`, `.chip`, `.media-pill`). A system stack —
   `ui-monospace, SFMono-Regular, Menlo, monospace` — is visually near-identical at
   `.62–.72rem` and removes an entire font download. **Zero visual regression, one
   fewer blocking dependency.**
2. Load the remaining CSS non-blocking:
   ```html
   <link rel="preload" as="style" href="...">
   <link rel="stylesheet" href="..." media="print" onload="this.media='all'">
   ```

### 1.6 Minor JS costs

- A global `pointerdown` listener appends a DOM node for **every click anywhere on
  the page** (impact rings). Cheap individually, but it runs on touch taps too.
- 3D-tilt handlers attach to all 15 `.card` elements and magnetic-button handlers to
  all 4 `.btn`/`.nav-cta`/`.email-btn` elements. Consider gating the tilt to
  above-the-fold cards only.

Both are already correctly guarded by `prefers-reduced-motion` and
`(hover: hover) and (pointer: fine)` — that part is well done.

### 1.7 Credit where due: CLS is probably already fine

None of the 20 `<img>` tags carry `width`/`height` attributes, which usually means
layout shift — but I checked the CSS and nearly every container reserves its own
space: `.deck-cover` `aspect-ratio:4/5`, `.fight-photo` `height:240px`,
`.brand-photo` `height:220px`, `.proj-media` `aspect-ratio:4/3`, and the
`.proof-*` images absolutely positioned inside `min-height` boxes. **The real problem
here is wasted bytes, not layout shift.** The single gap is `.logo-slot img`
(`max-height:54px`, no width reserved) — add dimensions there and to the rest as a
correctness measure.

---

# 2. SEO

### What is already strong
- Complete Open Graph **and** Twitter Card, with `og:image:width/height` and
  `og:image:alt` — better than most sites.
- Valid `Person` JSON-LD with `alternateName`, `homeLocation`, `email`, and 7 `sameAs` links.
- Clean heading hierarchy: exactly **1 `<h1>`, 11 `<h2>`, 24 `<h3>`**, no level skips.
- Canonical URL present; descriptive alt text on all 20 images.
- `meta description` at 159 characters — right in the ideal window.

### 2.1 Missing `robots.txt` and `sitemap.xml` — verified absent
Neither file exists in the repo, and neither is in the build script. For a single-page
site this is low-effort, high-signal:
```
User-agent: *
Allow: /
Sitemap: https://michaelheckert.com/sitemap.xml
```

### 2.2 Title tag is 67 characters — verified
> `Michael "King Killer" Heckert — BKFC Pro Fighter, Founder & Builder`

Google truncates around 580 px (~60 chars). "Founder & Builder" is likely being cut.
Suggested: **`Mike "King Killer" Heckert — BKFC Pro Fighter & Founder`** (54 chars).
This also matches how the page addresses itself ("Mike" in the `<h1>` and nav logo).

### 2.3 Five ready-made FAQs are not marked up
The FAQ block (`<details>`/`<summary>`, line 1019) contains 5 Q&As that are ideal
`FAQPage` candidates for rich results. Adding them is a ~20-line JSON-LD insert with a
real SERP-real-estate payoff.

### 2.4 Under-used structured data
The fight record is highly structured (opponent, event, venue, date, result) but is
plain prose. Adding `SportsEvent` / `SportsOrganization` markup targets
"mike heckert bkfc record" queries. Likewise no `Organization` markup for
King Killers or OurCoordinates, and no `WebSite`/`ProfilePage` wrapper.

### 2.5 Duplicate file shipped in the repo
**`portfolio-3.html` is byte-identical to `index.html`** (verified with `diff` — no
output, both 96,309 bytes). It is not copied by `npm run build`, so it is not
currently a live duplicate-content risk, but it is a 96 KB maintenance trap: edit one,
forget the other. Delete it.

### 2.6 Build output is committed to git
`dist/` is **23 tracked files / 4.8 MB** and is **not** in `.gitignore`. The build
script starts with `rm -rf dist`, so committing it is pure duplication of `assets/`.

**Fix:** add `dist/` to `.gitignore` and `git rm -r --cached dist`.

---

# 3. CRO — the highest-leverage fix on this page

### 3.1 Three overlapping sponsorship sections dilute the ask

The page has **ten sections**, and three of them are competing sponsorship pitches:

| § | Section | Contains |
|---|---|---|
| 04 | **Brand Deal Room** | Why-this-is-a-buy, best-fit categories, 4 deliverables, audience snapshot, procurement promises, proof strip, CTA |
| 05 | **Sponsor Tools** | Value planner, appearance booking, proof library, **Private Sponsor HQ** (nested `<h2>`), partnership ladder, categories, deliverable menu, brand-safe standards, logo wall |
| 06 | **Partner with me** | Fight-cycle tabs, **3 pricing tiers**, 5 FAQs, deck download |

The same content appears 2–3 times across them: sponsor categories appear in §4
(`.brand-fit`) **and** §5 (`.category-board`); deliverables appear in §4
(`.deal-flow`) **and** §5 (`.menu-grid`) **and** §6 (tier lists); usage rights appear
in all three.

A brand manager scrolling this cannot identify the single next action. **This is the
most valuable change in this audit:** consolidate §§4–6 into one sponsorship section
with a clear hierarchy — *case → packages → FAQ → one CTA*.

### 3.2 A CTA whose label contradicts its destination
Line 607:
```html
<a href="#contact">Get the sponsor deck</a>
```
Label promises a deck; it scrolls to a contact form. There are already 4 real
deck-download links on the page. Point this at
`Heckert-Fight-Sponsorship-Deck.pdf` or relabel it "Talk to me about sponsoring".

### 3.3 No analytics at all — verified `0` matches
`grep` for `gtag|analytics|plausible|umami|clarity|pixel|dataLayer` returns nothing.
There are 4 `mailto:` conversion points and 4 deck downloads on the page, and
currently **no way to know which ones work.** Every CRO recommendation below is
untestable until this is fixed. A privacy-respecting option (Plausible/Umami, ~1 KB)
plus click events on the two primary CTAs is the minimum viable instrumentation.

### 3.4 `mailto:` is a leaky conversion path
All four conversions open the visitor's mail client. This fails silently for webmail
users, corporate MDM setups, and most mobile browsers. At minimum, add a real form
(Formspree/Resend/Cloudflare Worker) as a fallback, or a Calendly link for the
appearance-booking flow.

### 3.5 The reaction game interrupts the conversion path
"Beat the Bell" sits inside `#fights`, **between the fight photos and the
sponsorship CTA** (`.sponsor-note`, line 605). It is a genuinely good signature
element — but it is placed directly in front of the primary conversion. Move it after
the sponsor note, or to `#about`.

### 3.6 No price anchoring
All three tiers read "Investment: custom, built per fight cycle." That is a legitimate
strategy, but it forces an email before any qualification. **Worth an A/B test:**
a "starting at $X" range typically *increases* qualified lead volume by filtering out
mismatched budgets. Unverified — this needs the analytics from 3.3 first.

---

# 4. Layout & UX

### 4.1 Mobile has no navigation — highest-impact UX bug
```css
@media(max-width:760px){.nav-links{display:none}}   /* line 88 */
```
There is **no hamburger, drawer, or toggle anywhere** (verified: 0 matches for
`hamburger|menu-toggle|navToggle|mobile-menu`). On any phone, the 8 section links
vanish and only the logo and "Work with me" survive. On a 10-section page, that forces
a very long scroll to reach anything.

**Fix:** a slide-in drawer, or at minimum a horizontally-scrollable chip row of the
main 4–5 destinations.

### 4.2 Ten sections is a long single page
Sections 01–10 stack into a very deep scroll. Combined with 3.1, the page reads as
"long" rather than "comprehensive." Tightening §§4–6 into one section would cut
roughly a third of the scroll depth and sharpen the narrative.

### 4.3 The same photo is reused for three different claims
`media-king-killer-arena.jpg` is used 3×: hero portrait, "fight-camp physique"
(§02 brands) and "fight-night promotional training visual" (§08 projects).
`fight-clearwater-victory.jpg` and `media-king-killers-portrait.jpg` are each used 2×.
Reusing one image under three different captions weakens the proof value of each.

### 4.4 `.pptx` is deployed but never linked
`Heckert-Fight-Sponsorship-Deck.pptx` (313 KB) is copied by the build script but has
**0 references** in `index.html`. Either link it as an "editable deck" for sponsors
who want to rebrand slides, or drop it from the build.

### 4.5 Two assets are dead weight
`sponsor-deck-cover.png` (43 KB) and `sponsor-deck-cover-king-killer.svg` (3 KB) are
never referenced. Safe to delete.

---

# 5. Accessibility

### 5.1 No `<main>` landmark and no skip link — verified `0` each
The body is `nav` → `header.hero` → ticker `div` → 10 `section`s → `footer`, with no
`<main>` wrapper. Screen-reader users get no way to jump past the nav, and the
document has no main landmark.

**Fix:** wrap the content in `<main id="main">` and add a visually-hidden
"Skip to content" link as the first body child.

### 5.2 Twelve `aria-label`s on plain `<div>`s are not exposed
Verified 12 instances, e.g.:
```html
<div class="ticker" aria-label="Headline stats">
<div class="fight-media reveal" aria-label="Latest BKFC Clearwater fight photos">
<div class="proof-strip reveal" aria-label="Sponsor proof points">
```
`aria-label` on a generic `<div>` with no role is ignored by assistive tech (ARIA in
HTML spec). Only `.appearance-options`, which correctly sets `role="group"`, actually
works. **Fix:** add `role="group"` (or `"list"`/`"region"`) wherever the label carries
meaning, or drop the attribute.

### 5.3 Contrast failure at small text size
Computed WCAG ratios from the `:root` tokens:

| Pair | Ratio | AA (4.5) |
|---|---|---|
| `--progress` `#9A6B00` on `--progress-bg` `#FCF1D6` | **4.18** | **FAIL** |
| `--muted` `#5B6376` on `--paper` | 5.40 | pass |
| `--muted` on `--card` | 6.02 | pass |
| `--accent-ink` on paper | 6.65 | pass |
| `--accent` `#E01023` on white | 4.92 | pass |
| deal-room `#B9C0CF` on `#0F141F` | 10.09 | pass |

The failing pair is `.chip-progress` (line 336) — the "◐ IN PROGRESS" chips — at
`font-size:.68rem` (~10.9 px). Darken `--progress` to about `#855D00` to clear 4.5.

Also: `--gold` (`#B18A3C`) is declared in `:root` and **never used** anywhere.
It would fail at 2.87 — remove the token.

### 5.4 `aria-live="polite"` on a `<button>`
The reaction game button carries `aria-live` (line 594). Live-region semantics belong
on the output container, not the control. Move it to `.game-foot` / `#verdict`.

### 5.5 What is already done well
- `prefers-reduced-motion` handled in **both** CSS (line 457 block) and JS.
- `:focus-visible` outline defined globally with 3 px accent.
- Scroll handler is `rAF`-throttled and `passive`.
- All external links carry `rel="noopener"`.

---

# 6. Prioritised roadmap

Ordered by impact ÷ effort.

### P0 — do first (a few hours, largest measurable win)
| # | Action | Expected effect |
|---|---|---|
| 1 | WebP/AVIF convert all rasters + `srcset`/`sizes` | **3.94 MB → 0.55 MB (measured, −86%)** |
| 2 | `loading="lazy" decoding="async"` on the 19 below-fold images | Faster LCP, less mobile data |
| 3 | `preload` + `fetchpriority="high"` on hero image | Direct LCP improvement |
| 4 | Drop JetBrains Mono → system mono stack | One fewer blocking font |
| 5 | Make Google Fonts CSS non-blocking | Faster FCP |
| 6 | Add mobile nav drawer | Fixes total loss of navigation on phones |
| 7 | Add `<main>` + skip link; fix the 12 `aria-label` divs | Real a11y gain, low effort |
| 8 | Fix `--progress` contrast to `#855D00` | Clears a WCAG AA failure |

### P1 — next (half a day, structural)
| # | Action | Expected effect |
|---|---|---|
| 9 | **Merge §§4–6 into one sponsorship section** | Clearest single CRO win on the page |
| 10 | Fix the line-607 CTA label/destination mismatch | Removes a broken promise at the point of intent |
| 11 | Add lightweight analytics + CTA click events | Makes everything else measurable |
| 12 | Add `robots.txt` + `sitemap.xml` (and to the build script) | Basic crawl hygiene |
| 13 | Add `FAQPage` JSON-LD for the 5 existing FAQs | Rich-result eligibility |
| 14 | Shorten title to ~54 chars | Stops SERP truncation |
| 15 | `.gitignore` `dist/` + `git rm -r --cached dist`; delete `portfolio-3.html` | −4.9 MB of repo duplication |

### P2 — polish
| # | Action |
|---|---|
| 16 | Replace `mailto:` with a real form or booking link |
| 17 | Move the reaction game out of the primary conversion path |
| 18 | Add `SportsEvent` / `Organization` structured data |
| 19 | Source unique imagery for the 5 duplicated photo slots |
| 20 | Link or remove the orphaned `.pptx`; delete the 2 unused assets |
| 21 | Remove the unused `--gold` token; scope tilt effects to above-fold cards |
| 22 | A/B test price anchoring on the tier cards (needs #11 first) |

---

## Notes on what I could not verify

- **Lighthouse / Core Web Vitals scores (LCP / CLS / INP).** Genuinely blocked here,
  and I tried: `npm` registry is reachable (I installed `puppeteer` + `lighthouse`),
  but the Chrome download host is not — `npx puppeteer browsers install chrome` fails
  with *"All providers failed for chrome 152.0.7977.75"*, no system browser is present
  (`chromium`, `chrome`, `firefox` all absent), and `apt-get update` cannot reach
  `deb.debian.org`. So LCP/CLS/INP above are **reasoned from payload and markup, not
  measured.** Run Lighthouse against the live URL for real field data.
- **Visual quality of the WebP/AVIF conversions.** The byte savings in §1.3 are real
  measurements from ImageMagick's `libwebp 1.2.4` encoder on these exact files, but I
  did not eyeball every output. Spot-check the LCP hero and the fight photos at q80
  before shipping; drop to q82–85 if you see banding in the dark arena shots.
- **Actual Google Fonts `woff2` byte weight.** I could fetch the CSS (to count the 27
  `@font-face` rules and 3 latin files) but not `fonts.gstatic.com` itself, so the
  *sizes* of those 3 files are unconfirmed.
- **Layout shift (CLS).** Marked up with **no** `width`/`height` attributes on any of
  the 20 images, which normally causes CLS — but I checked the CSS and nearly every
  container reserves space (`.deck-cover` `aspect-ratio:4/5`, `.fight-photo`
  `height:240px`, `.brand-photo` `height:220px`, `.proj-media` `aspect-ratio:4/3`,
  `.proof-*` absolutely positioned inside `min-height` boxes). **CLS is probably
  already fine** — this is a correctness issue, not a measured regression. The one
  gap is `.logo-slot img` (`max-height:54px`, no width reserved).
- **"3,000+ pixels below the fold" (§1.1)** is an estimate from section ordering, not
  a measured scroll offset.
- **Live-site behaviour.** This audit is of the repository at `4685079`; CDN caching,
  compression, and hosting config on the deployed site may already mitigate some
  transfer-size findings. The 3.94 MB figure is the raw file weight, not the
  over-the-wire weight.
