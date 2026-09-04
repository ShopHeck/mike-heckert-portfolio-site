# Mike Heckert Portfolio Site

Personal portfolio and sponsorship website for professional BKFC fighter Mike "King Killer" Heckert.

## Files

- `index.html` is the public static site entrypoint (markup, CSS and JS are all inline).
- `assets/` contains the BKFC Clearwater fight photos, sponsor/brand media, and the
  `social-share-king-killer.jpg` preview image used by social platforms.
- `assets/gen/` holds the generated responsive image variants (AVIF + WebP at several
  widths). These are committed because the build is a plain copy step.
- `tools/gen-images.sh` regenerates `assets/gen/` from the originals.
- `robots.txt` and `sitemap.xml` are served from the site root.
- `Heckert-Fight-Sponsorship-Deck.pdf` and `Heckert-Fight-Sponsorship-Deck.pptx` are
  the downloadable sponsor decks (PDF for reading, PPTX for co-branding).
- `worker/index.js`, `package.json`, and `.openai/hosting.json` support the current
  Sites deployment package.
- `AUDIT.md` is the performance / SEO / CRO / accessibility audit this codebase was
  optimised against.

## Local Preview

```sh
npm run preview
```

Then open `http://localhost:4173`.

## Images

Rasters are served through `<picture>` with AVIF and WebP sources plus `srcset`/`sizes`,
falling back to the original JPEG/PNG. After replacing or adding a photo in `assets/`,
regenerate the variants (needs ImageMagick built with `libwebp` and AVIF delegates):

```sh
npm run images
```

New images also need an entry in the `IMAGES` list at the top of `tools/gen-images.sh`,
and a `sizes` value that matches the CSS slot they render into.

## Build

```sh
npm run build
```

This creates `dist/` for the Sites/Cloudflare-compatible deployment bundle. `dist/` is
build output and is gitignored — it is regenerated on every build.

## Analytics

Every CTA carries a `data-track` attribute and clicks are captured by the `track()`
helper at the top of the inline script. It writes to `window.dataLayer` and logs to the
console on `localhost`. To start collecting, set `ANALYTICS.provider` to `'plausible'`
or `'ga4'` in `index.html` and add the matching snippet — no markup changes needed.

## Simple Static Hosting

For Netlify, Cloudflare Pages, GitHub Pages, or similar static hosting, the required public files are:

- `index.html`
- `assets/` (including `assets/gen/`)
- `robots.txt`
- `sitemap.xml`
- `Heckert-Fight-Sponsorship-Deck.pdf`
- `Heckert-Fight-Sponsorship-Deck.pptx`
