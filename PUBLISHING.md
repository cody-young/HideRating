# Publishing HideRating

Releases are built by [BigWigsMods/packager](https://github.com/BigWigsMods/packager)
in [.github/workflows/release.yml](.github/workflows/release.yml). Pushing a
tag builds the zip, creates a GitHub release, and uploads to whichever
platforms are configured below. Everything in this file is a one-time setup;
after that, releasing is just a tag.

## 1. CurseForge

1. Create the project at <https://legacy.curseforge.com/wow/addons/create>.
   Category: PvP. License: GNU General Public License version 3 (GPLv3).
2. Copy the **Project ID** from the project page sidebar.
3. In [HideRating.toc](HideRating.toc), uncomment and fill the line:
   `## X-Curse-Project-ID: <id>`
4. Add the repo secret `CF_API_KEY` (Settings → Secrets and variables →
   Actions). The token comes from <https://legacy.curseforge.com/account/api-tokens>
   — the same one already used by HealerCursor and ArenaTalentReminder.

## 2. Wago

1. Create the project at <https://addons.wago.io/> (Add-ons → Upload).
2. Copy the project's **ID** (the slug shown on the project page).
3. In [HideRating.toc](HideRating.toc), uncomment and fill the line:
   `## X-Wago-ID: <id>`
4. Add the repo secret `WAGO_API_KEY` (or `WAGO_API_TOKEN` — the workflow
   accepts either) from <https://addons.wago.io/account/apikeys>.

## 3. Release

```sh
git add HideRating.toc
git commit -m "Add CurseForge and Wago project IDs"
git push
git tag 1.0.0
git push origin 1.0.0
```

The workflow runs on the tag. Watch it with `gh run watch -R cody-young/HideRating`.

Notes:

* The `## Version:` line is `@project-version@` on purpose — the packager
  substitutes the tag name at build time. In-game it reads `dev` when running
  straight from the repo.
* A missing `CF_API_KEY` or `X-Curse-Project-ID` skips that platform rather
  than failing the build, so you can publish to one platform first and add the
  other later.
* `.pkgmeta` keeps `.github/`, `.gitignore`, `.pkgmeta`, and this file out of
  the packaged zip.

## Updating the interface version

`## Interface:` lists every client build the addon declares support for. Bump
it when a patch ships, otherwise the addon shows as out of date in-game.
