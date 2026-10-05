# Ventura bottles

Small Homebrew tap for Intel macOS Ventura. Bottles built on `vm-macos13-bldr`
(Ventura 13.7.8, `/usr/local`), distributed through public GitHub Releases.
Currently supplies `tree`; this is not a homebrew/core mirror.

## Install on Deus

```sh
HOMEBREW_NO_AUTO_UPDATE=1 brew tap sevaiam/ventura
brew trust --formula sevaiam/ventura/tree
HOMEBREW_NO_AUTO_UPDATE=1 brew install --force-bottle sevaiam/ventura/tree
```

If core `tree` is installed, uninstall it before installing this tap's formula.
Use fully qualified names. `--force-bottle` avoids silently building from source.
No GitHub token needed for installing public bottles. No developer-mode override needed.

## Update only this tap

Keep `HOMEBREW_NO_AUTO_UPDATE=1` in `/usr/local/etc/homebrew/brew.env`.
`brew update` explicitly updates Homebrew itself despite this setting; do not use
it on pinned hosts. Instead:

```sh
git -C "$(brew --repo sevaiam/ventura)" pull --ff-only
HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade --force-bottle sevaiam/ventura/tree
```

## Build on VM

Builder uses pinned Homebrew 7.0.7, commit
`8e858db5584704dcd469b8e826228c0d5a5a94f6`, and CLT 15.1.
Keep VM's window-close behavior set to keep running.

Work only in dedicated Git worktree at Homebrew tap path:
`/usr/local/Homebrew/Library/Taps/sevaiam/homebrew-ventura`.
Bare repository lives at `~/builder-repos/homebrew-ventura.git`.
Builder branch uses `noticket-` prefix and tracks `origin/main`.
Do not store GitHub publishing credentials on VM.

From clean tap worktree:

```sh
git fetch origin
git merge --ff-only origin/main
./scripts/build-bottle.sh tree
```

Script checks Intel/Ventura and pinned Brew commit, grants formula-specific trust,
removes only selected formula's existing keg, builds from source, runs formula
test, downloads/checks corresponding source,
bottles into `~/builder-artifacts/<release-tag>`, and updates bottle block without
committing. Default timestamped tags keep assets immutable. `RELEASE_TAG` can be
set explicitly for a first release; never overwrite published assets.
Build dependencies need their own compatible bottles or must also be built on VM.

### Portable Ruby header prerequisite

Portable Ruby 4.0.7 declares `HAVE_STDCKDINT_H=1`; Apple's CLT 15.1 lacks that header.
Builder has unchanged LLVM 18.1.8 `stdckdint.h` at
`~/builder-toolchain/llvm-18.1.8/include/`, checked with SHA-256
`808854b229028d66012bef0eb5f7cccb2d9a228edcdc5eb2bc710bc7cea4b25a`.
Source: https://raw.githubusercontent.com/llvm/llvm-project/llvmorg-18.1.8/clang/lib/Headers/stdckdint.h

`~/.bundle/config` scopes private include path and macOS SDK path to native
`bigdecimal` build. Initial bottle gems were installed directly with portable
Ruby's Bundler and `BUNDLE_WITH=bottle`, since Brew sanitizes Bundler environment
flags. No Homebrew source or system headers patched. This header is needed only
for builder's Ruby tooling, not by Deus to pour bottles.

## Publish from maintainer machine

1. Copy artifact directory and changed formula from VM into dedicated local
   `noticket-*` worktree. Review formula diff and verify bottle SHA-256 matches JSON.
2. Rename local bottle to JSON's `bottle.tags.ventura.filename` before uploading.
   Brew emits a double-hyphen local filename, but download filename uses one hyphen.
3. Commit tested formula and publish release with bottle, JSON and checked source
   archive. Include original source alongside GPL binaries. Use tag from JSON's
   `bottle.root_url`, targeting tested source commit. Example:

   ```sh
   gh release create "$release" --repo sevaiam/homebrew-ventura \
     --target "$source_commit" --title "$release" \
     --notes 'Intel Ventura bottle. Matching source archive included.' \
     "$bottle" "$json" "$source_archive"
   ```

4. Merge reviewed PR before consumers pull `main`. Test installation with
   `--force-bottle`; check `INSTALL_RECEIPT.json` records
   `poured_from_bottle: true` and `source.tap: sevaiam/ventura`.

Tap recipes adapted from Homebrew and scripts licensed BSD-2-Clause (see LICENSE).
Packaged programs retain their upstream licenses; `tree` is GPL-2.0-or-later.
