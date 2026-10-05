#!/bin/sh
# Run inside this tap's dedicated builder worktree. No publishing credentials needed.
set -eu

name=${1:?Usage: scripts/build-bottle.sh FORMULA}
case "$name" in *[!a-z0-9@+._-]*|"") echo 'Invalid formula name' >&2; exit 1;; esac
[ "$(uname -m)" = x86_64 ] || { echo 'Intel builder required' >&2; exit 1; }
case "$(sw_vers -productVersion)" in 13.*) ;; *) echo 'Ventura builder required' >&2; exit 1;; esac

brew=/usr/local/bin/brew
repo=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
[ "$(git -C "$("$brew" --repo)" rev-parse HEAD)" = 8e858db5584704dcd469b8e826228c0d5a5a94f6 ] || {
  echo 'Builder must use pinned Homebrew 7.0.7' >&2; exit 1;
}
[ -f "$repo/Formula/$name.rb" ] || { echo 'Formula not found in this tap' >&2; exit 1; }
git -C "$repo" diff --quiet
git -C "$repo" diff --cached --quiet
export HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 HOMEBREW_NO_AUTOREMOVE=1
formula="sevaiam/ventura/$name"
[ "$(CDPATH= cd -- "$("$brew" --repo sevaiam/ventura)" && pwd -P)" = "$repo" ] || {
  echo 'Install this worktree at Homebrew tap path first' >&2; exit 1;
}
"$brew" trust --formula "$formula"
info=$("$brew" info --json=v2 "$formula")
version=$(printf '%s' "$info" | /usr/bin/python3 -c 'import json,sys; f=json.load(sys.stdin)["formulae"][0]; print(f["versions"]["stable"] + ("_" + str(f["revision"]) if f["revision"] else ""))')
release=${RELEASE_TAG:-$name-$version-$(date -u +%Y%m%dT%H%M%SZ)}
case "$release" in *[!a-zA-Z0-9@+._-]*|"") echo 'Invalid release tag' >&2; exit 1;; esac
git check-ref-format "refs/tags/$release"
out="$HOME/builder-artifacts/$release"
[ ! -e "$out" ] || { echo "Output already exists: $out (use new RELEASE_TAG)" >&2; exit 1; }
mkdir -p "$out"

# reinstall does not support --build-bottle. Remove only selected keg, then build.
if "$brew" list --formula | grep -Fxq "$name"; then
  "$brew" uninstall "$name" < /dev/null
fi
"$brew" install --build-bottle "$formula" < /dev/null
"$brew" test "$formula" < /dev/null
source_url=$(printf '%s' "$info" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)["formulae"][0]["urls"]["stable"]["url"])')
source_sha=$(printf '%s' "$info" | /usr/bin/python3 -c 'import json,sys; print(json.load(sys.stdin)["formulae"][0]["urls"]["stable"]["checksum"])')
curl -fL --retry 2 "$source_url" -o "$out/$name-$version.source.tar.gz"
printf '%s  %s\n' "$source_sha" "$out/$name-$version.source.tar.gz" | shasum -a 256 -c -
cd "$out"
"$brew" bottle --no-rebuild --json --root-url="https://github.com/sevaiam/homebrew-ventura/releases/download/$release" "$formula" < /dev/null
set -- "$out/$name"--*.bottle.json
[ "$#" = 1 ] && [ -f "$1" ] || { echo 'Expected one bottle JSON file' >&2; exit 1; }
"$brew" bottle --merge --write --no-commit "$1" < /dev/null
printf '\nRELEASE_TAG=%s\nARTIFACT_DIR=%s\n' "$release" "$out"
echo 'Review generated Formula diff; upload bottle (JSON filename), JSON and source archive; commit formula via PR.'
