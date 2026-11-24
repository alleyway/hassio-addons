# Contributing to Alleyway Home Assistant Add-ons

Thank you for your interest in contributing!

This repository follows the standard structure for a [Home Assistant add-on repository](https://developers.home-assistant.io/docs/apps/repository).

## Reporting Issues

Please use [GitHub Issues](https://github.com/alleyway/hassio-addons/issues).

## Development

1. Fork and clone the repository.
2. Make changes inside the relevant add-on directory (e.g. `ntopng/`).
3. Test locally where possible (build the Docker image or use the add-on on a test Home Assistant instance).
4. Update documentation in `DOCS.md` and `README.md` as needed.
5. Update `CHANGELOG.md` when making user-visible changes.

## Releasing a New Version of an Add-on

The single source of truth for an add-on's version is the `version:` field in its `config.yaml`.

### Recommended Release Steps

1. Make your code, Dockerfile, or configuration changes.
2. Bump the version in that add-on's `config.yaml` (e.g. `ntopng/config.yaml` or `urbit/config.yaml`).
   - Follow [Semantic Versioning](https://semver.org/):
     - PATCH for bug fixes and dependency updates.
     - MINOR for new features.
     - MAJOR for breaking changes.
3. Add an entry at the top of that add-on's `CHANGELOG.md` describing the changes.
4. Commit your changes to the `main` branch (via PR if desired).
5. Create a new GitHub Release:
   - Tag: `vX.Y.Z` (or `X.Y.Z`) — it **must** match the version in that add-on's `config.yaml` (the workflow validates this).
   - The tag must match exactly one add-on. If two add-ons share a version, the build fails rather than guessing.
   - Use the release notes to summarize changes (you can link to or copy from `CHANGELOG.md`).
6. The "Build and Publish" workflow will trigger on the published release:
   - It selects the add-on whose `version` matches the tag.
   - Validates the tag matches that version.
   - Builds images for the architectures listed for that add-on, using the official Home Assistant builder actions.
   - Pushes to `ghcr.io/alleyway/hassio-addon-<slug>` with the version and `latest` tags.
   - Publishes the multi-arch manifest (or the single-arch manifest, for an add-on that only builds one architecture).

You can also trigger the workflow manually via **Actions → Build and Publish → Run workflow** and pick the add-on.

### After Release

- Users will see the update in the Home Assistant add-on store after the Supervisor refreshes the repository.
- The `latest` tag is updated for convenience.
- Consider updating any external documentation or the community forum thread.

## Adding a New Add-on

1. Create a new directory (e.g. `myaddon/`).
2. Add the standard files: `config.yaml`, `Dockerfile`, `rootfs/`, `DOCS.md`, `README.md`, `icon.png`, `logo.png`, `CHANGELOG.md`.
3. Update the root `repository.yaml` if needed (usually not).
4. Add the add-on to the `addon_meta` case in `.github/workflows/build.yml` (image name and architectures). A release tag that matches its `config.yaml` version builds that add-on.
5. Update the root `README.md`.

## Style & Tooling

- Use LF line endings.
- YAML is the preferred format for `config.yaml`.
- Keep the build context minimal.
- Prefer the official `ghcr.io/hassio-addons/*` base images when possible.

## Questions?

Open an issue or ask in the linked community forum thread for the ntopng add-on.

---

This process is based on the [Home Assistant add-on publishing guidelines](https://developers.home-assistant.io/docs/apps/publishing) and the behavior of the repository's GitHub Actions workflow.