#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 1 || ! $1 =~ ^v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
  echo 'Usage: bash scripts/update-release.sh vX.Y.Z' >&2
  exit 2
fi
version=${BASH_REMATCH[1]}
fake_hash=sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=

cd "$(dirname "$0")/.."
work=$(mktemp -d /tmp/ibis-release.XXXXXXXXXX)
[[ $work =~ ^/tmp/ibis-release\.[A-Za-z0-9]{10}$ ]]
trap 'rm -r -- "${work:?}"' EXIT
cp flake.nix flake.lock package.nix "$work/"

manifest() {
  jq -n --arg version "$version" --arg sourceHash "$1" --arg cargoHash "$2" \
    '{ $version, $sourceHash, $cargoHash }'
}

prefetch_hash() {
  local log="$work/nix.log" hash
  # Use Nix's fixed-output hash mismatch to get the expected SRI hash.
  if LC_ALL=C NO_COLOR=1 nix build --no-write-lock-file --no-link "path:$work#ibis-office.$1" >"$log" 2>&1; then
    echo "Nix unexpectedly accepted the placeholder hash for $1" >&2
    return 1
  fi
  hash=$(awk '$1 == "got:" && NF == 2 { print $2 }' "$log")
  if ! awk -v fake="$fake_hash" '/hash mismatch in fixed-output derivation/ { mismatch = 1 }
      $1 == "specified:" && $2 == fake { placeholder = 1 }
      END { exit !(mismatch && placeholder) }' "$log" ||
      [[ ! $hash =~ ^sha256-[A-Za-z0-9+/]{43}=$ ]]; then
    awk '{ print }' "$log" >&2
    return 1
  fi
  printf '%s\n' "$hash"
}

manifest "$fake_hash" "$fake_hash" > "$work/release.json"
source_hash=$(prefetch_hash src)
manifest "$source_hash" "$fake_hash" > "$work/release.json"
cargo_hash=$(prefetch_hash cargoDeps)
manifest "$source_hash" "$cargo_hash"
