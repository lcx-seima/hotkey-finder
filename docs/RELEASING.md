# Releasing Hotkey Finder

GitHub Actions builds every pull request and push to `main`. A tag matching
`vMAJOR.MINOR.PATCH` additionally creates an ad-hoc-signed GitHub Release. Both
workflows use GitHub-hosted macOS runners; a self-hosted runner and repository
secrets are not required.

## Important limitation

The published app is signed ad hoc so macOS privacy controls can identify the
current app bundle. It is not signed with an Apple Developer ID certificate and
is not notarized by Apple, so macOS Gatekeeper will still block its first
launch. Ad-hoc identities are tied to a specific build, which means users may
need to grant privacy permissions again after installing an update. The release
notes and README must continue to disclose these limitations.

## Publish a release

1. Update `MARKETING_VERSION` in the Xcode project and merge the change into
   `main`.
2. Create and push a matching annotated tag:

   ```bash
   git switch main
   git pull --ff-only
   git tag -a v0.1.1 -m "Release v0.1.1"
   git push origin v0.1.1
   ```

3. Follow the **Release** workflow in the repository's Actions tab.

The workflow verifies that the tag matches `MARKETING_VERSION`, builds an
universal `arm64`/`x86_64` app, ad-hoc signs the complete app bundle using its
bundle identifier, verifies that signature, and publishes these assets:

- `Hotkey-Finder.zip`
- `Hotkey-Finder.zip.sha256`

The stable latest-download URL is:

```text
https://github.com/lcx-seima/hotkey-finder/releases/latest/download/Hotkey-Finder.zip
```

Release notes are generated automatically from merged pull requests and commit
history. No Apple certificate or App Store Connect credential is used. A
Developer ID signature and notarization should replace ad-hoc signing if those
credentials become available later.
