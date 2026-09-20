export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    // michaelheckert.com/portal → the standalone 360° sponsorship portal (deep links like /portal/#SB-R1 keep their hash).
    if (url.pathname === "/portal" || url.pathname.startsWith("/portal/")) {
      const rest = url.pathname.slice("/portal".length).replace(/^\/+/, "");
      return Response.redirect(`https://heck-sponsor-360.netlify.app/${rest}${url.search}`, 301);
    }
    return env.ASSETS.fetch(request);
  }
}
