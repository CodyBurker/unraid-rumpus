# unraid-rumpus

Unraid packaging for [Rumpus](https://github.com/rodwilco/rumpus) — a
self-hosted Jackbox-style party game platform (one shared TV screen at
`/host`, phones as controllers at `/play`). Upstream is AGPLv3.

This repo contains:

- **`.github/workflows/publish.yml`** — builds the upstream source at the
  commit pinned in `UPSTREAM_REF` and publishes `ghcr.io/codyburker/rumpus`
  (`:latest` plus the commit SHA as a tag).
- **`rumpus.xml`** — Unraid Docker template (dockerMan / Community
  Applications format).
- **`rumpus-icon.png`** — app icon referenced by the template.
- **`UPSTREAM_REF`** — the upstream commit the image is built from.

## One-time setup

1. **Make the GHCR package public** (after the first successful workflow run):
   https://github.com/users/CodyBurker/packages/container/rumpus/settings →
   Danger Zone → Change visibility → Public. Unraid pulls anonymously, so a
   private package will fail to pull.
2. **Make this repo public** so the template and icon raw URLs resolve for
   Unraid (and as a prerequisite for a Community Applications submission):
   repo Settings → General → Danger Zone → Change visibility.

## Installing on Unraid

Two options:

**A. Template repository (recommended)** — On the Unraid Docker tab, scroll
to **Template Repositories**, add
`https://github.com/CodyBurker/unraid-rumpus`, and save. Then **Add
Container** → pick *Rumpus* from the Template dropdown → Apply.

**B. User template on the flash drive** — copy `rumpus.xml` to
`/boot/config/plugins/dockerMan/templates-user/my-rumpus.xml` on the server,
then **Add Container** → select it under User templates.

Defaults: host port **8012** → container 3000, bridge network, no volumes.
After starting, open `http://<server-ip>:8012/host` on the TV and
`http://<server-ip>:8012/play` on phones.

## Updating the app

Upstream has no releases/tags, so the image is pinned to a commit. To update:
put the new upstream commit SHA in `UPSTREAM_REF`, push to `main` (the
workflow publishes a fresh image), then use Unraid's *force update* /
*check for updates* on the container.

## Publishing to the real Community Applications store

To make Rumpus installable from Unraid's **Apps** tab for everyone:

1. Repo and package must be public (see above).
2. Review the template against the [CA template schema and policies]
   (https://forums.unraid.net/topic/38619-docker-template-xml-schema/).
3. Create a support thread on the Unraid forums and set its URL in
   `<Support>`.
4. Submit this repo to Community Applications per the CA moderators'
   process (post in the Unraid forums; a moderator reviews and adds the
   repo to the CA appfeed).

Until it's accepted into CA, options A/B above give the same install
experience on your own server.

## Notes / limitations

- Rooms are in-memory and ephemeral: a container restart clears them. No
  persistent volume is needed or used.
- No authentication by design — keep it LAN-only; don't reverse-proxy it to
  the internet.
- Optional: mount a full Cards Against Humanity deck (`cah-cards.js`
  exporting `{ WHITE: [...], BLACK: [...] }`) over
  `/app/games/data/cah-cards.js` (the template has an advanced path config
  for this). The real CAH text is CC BY-NC-SA and is not distributed here.
