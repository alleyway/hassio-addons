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
2. Bump the version in `ntopng/config.yaml` (e.g. from `"0.3.0"` to `"0.3.1"` or `"0.4.0"`).
   - Follow [Semantic Versioning](https://semver.org/):
     - PATCH for bug fixes and dependency updates.
     - MINOR for new features.
     - MAJOR for breaking changes.
3. Add an entry at the top of `ntopng/CHANGELOG.md` describing the changes.
4. Commit your changes to the `main` branch (via PR if desired).
5. Create a new GitHub Release:
   - Tag: `vX.Y.Z` (or `X.Y.Z`) — it **must** match the version in `config.yaml` (the workflow validates this).
   - Use the release notes to summarize changes (you can link to or copy from `CHANGELOG.md`).
6. The "Build and Publish" workflow will trigger on the published release:
   - It reads the version from `config.yaml`.
   - Validates the tag matches the version.
   - Builds multi-architecture images using the official Home Assistant builder actions.
   - Pushes to `ghcr.io/alleyway/hassio-addon-ntopng` with the version and `latest` tags.
   - Publishes the multi-arch manifest.

You can also trigger the workflow manually via **Actions → Build and Publish → Run workflow**.

### After Release

- Users will see the update in the Home Assistant add-on store after the Supervisor refreshes the repository.
- The `latest` tag is updated for convenience.
- Consider updating any external documentation or the community forum thread.

## Adding a New Add-on

1. Create a new directory (e.g. `myaddon/`).
2. Add the standard files: `config.yaml`, `Dockerfile`, `rootfs/`, `DOCS.md`, `README.md`, `icon.png`, `logo.png`, `CHANGELOG.md`.
3. Update the root `repository.yaml` if needed (usually not).
4. Extend `.github/workflows/build.yml` to handle the new add-on (or adopt the multi-app pattern from the [official apps-example](https://github.com/home-assistant/apps-example) if you add several).
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