# unraid-rumpus

Unraid packaging for a family of self-hosted LAN game platforms. Each app
gets a GHCR image built from a pinned, test-gated upstream commit, plus an
Unraid Docker template (dockerMan / Community Applications format).

| App | Upstream | Image | Host port | Notes |
|-----|----------|-------|-----------|-------|
| **Rumpus** | [rodwilco/rumpus](https://github.com/rodwilco/rumpus) (AGPLv3) | `ghcr.io/codyburker/rumpus` | 8012 → 3000 | Jackbox-style: TV at `/host`, phones at `/play`. Stateless. |
| **GameNight** | [abhijatchaturvedi/gamenight](https://github.com/abhijatchaturvedi/gamenight) | `ghcr.io/codyburker/gamenight` | 8013 → 4000 | Party games: Mongolpuri, UNO, Quiz, Tic Tac Toe, Scribble. Stateless; the Quiz game needs internet (opentdb.com). |
| **LAN Games** | [kbennett2000/lan-games](https://github.com/kbennett2000/lan-games) (MIT) | `ghcr.io/codyburker/lan-games` | 8014 → 3000 | 8 turn-based board games. Has accounts (JWT + bcrypt) and SQLite persistence — mount `/app/server/data`. `JWT_SECRET` is auto-generated on first boot and persisted in the data volume (`langames-entrypoint.sh`); set the variable only to override. |

Per app: a `publish-*.yml` workflow, a template XML, an icon PNG, and an
`UPSTREAM_REF*` file pinning the upstream commit the image is built from.
GameNight ships no Dockerfile upstream, so `Dockerfile.gamenight` here
supplies one; the others build with their upstream Dockerfile (LAN Games'
multi-stage build runs its full 600+ test suite during every image build).

## One-time setup

1. **Make each GHCR package public** (after its first successful workflow
   run) — Unraid pulls anonymously, so a private package will fail to pull:
   - https://github.com/users/CodyBurker/packages/container/rumpus/settings
   - https://github.com/users/CodyBurker/packages/container/gamenight/settings
   - https://github.com/users/CodyBurker/packages/container/lan-games/settings

   Danger Zone → Change visibility → Public.
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

Updates are automatic for all apps: `.github/workflows/auto-update.yml`
checks each upstream daily, runs that app's test suite against any new
commit (Rumpus: e2e suite; GameNight: tournament logic test; LAN Games:
jest unit + integration suites), and — only if tests pass — bumps the app's
`UPSTREAM_REF*` file and republishes its image. A commit that fails the
tests is skipped (the workflow run shows the failure) and retried the next
day against whatever upstream HEAD is then.

Manual override: put a specific upstream commit SHA in the app's
`UPSTREAM_REF*` file and push to `main`, or run its publish workflow by
hand.

Separately, each publish workflow also runs weekly (Mondays) so images are
rebuilt on a fresh base — that's how base-image security updates reach the
containers even when the apps themselves haven't changed.

On the Unraid side, install the **CA Auto Update Applications** plugin and
enable it for Rumpus to pull new images on its schedule automatically —
otherwise use the container's normal *check for updates* / *apply update*.
Note: an update restarts the container, which clears any in-progress game
rooms, so schedule auto-updates for a time you won't be mid-game.

Heads-up: GitHub disables cron schedules in repos with no commit activity
for ~60 days. If upstream goes quiet that long, GitHub emails you and the
Actions tab shows a "re-enable" button for the schedule.

## Publishing to the real Community Applications store

To make Rumpus installable from Unraid's **Apps** tab for everyone, submit
this repo through the Community Apps portal:

1. Repo and package must be public (done), and the repo must contain a
   `ca_profile.xml` and an OSI-approved LICENSE (both included here).
2. Go to https://ca.unraid.net/submit, sign in, and point it at
   `https://github.com/CodyBurker/unraid-rumpus`. A live scan validates the
   template XML and `ca_profile.xml`, checks for duplicates, and previews
   the listing before you submit.
3. Fix anything the scan flags, submit, and wait for moderator review.

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

## Licensing

The contents of this repository (Unraid templates, CI workflows, metadata,
and documentation) are MIT-licensed — see `LICENSE`. The packaged
applications are separate works by their upstream authors; each published
container image contains that app's code under its own license:

- **Rumpus** — AGPL-3.0-only (source: https://github.com/rodwilco/rumpus)
- **GameNight** — the README displays an MIT badge but the repo currently
  ships no LICENSE file; an issue should be raised upstream asking for one
  to be committed.
- **LAN Games** — MIT (source: https://github.com/kbennett2000/lan-games)
