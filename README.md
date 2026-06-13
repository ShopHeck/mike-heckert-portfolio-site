# Mike Heckert Portfolio Site

Personal portfolio and sponsorship website for professional BKFC fighter Mike "King Killer" Heckert.

## Files

- `index.html` is the public static site entrypoint.
- `assets/` contains the sponsor deck cover image, latest BKFC Clearwater fight photos, sponsor/brand media, and the `social-share-king-killer.jpg` preview image used by social platforms.
- `Heckert-Fight-Sponsorship-Deck.pdf` and `Heckert-Fight-Sponsorship-Deck.pptx` are linked/downloadable sponsor deck assets.
- `worker/index.js`, `package.json`, and `.openai/hosting.json` support the current Sites deployment package.

## Local Preview

```sh
python3 -m http.server 4173
```

Then open `http://localhost:4173`.

## Build

```sh
npm run build
```

This creates `dist/` for the Sites/Cloudflare-compatible deployment bundle.

## Simple Static Hosting

For Netlify, Cloudflare Pages, GitHub Pages, or similar static hosting, the required public files are:

- `index.html`
- `assets/`
- `Heckert-Fight-Sponsorship-Deck.pdf`
- `Heckert-Fight-Sponsorship-Deck.pptx`
