#!/usr/bin/env bash
# =============================================================================
# scripts/ci/verify-release.sh
# Verify a directory of Flavenz kernel release assets BEFORE upload (local
# pre-flight) and AFTER upload (downloaded assets).
#
# Usage:  scripts/ci/verify-release.sh <asset-dir>
#
# What it proves (and what it does NOT):
#   * SHA256SUMS.txt matches every listed asset (transport integrity);
#   * every asset in the directory is covered by SHA256SUMS.txt;
#   * the flashable zip contains anykernel.sh + LICENSE + PROVENANCE + Image;
#   * the Image inside the zip matches image_sha256 recorded in PROVENANCE.txt;
#   * PROVENANCE.txt is byte-identical inside the zip and as an asset;
#   * no boot image is attached (release policy: unsigned/no AVB images are
#     never CI release assets);
#   * the declared signing status matches reality (GPG signature present and
#     verifiable, or an explicit UNSIGNED statement). It never claims a
#     signature that does not exist.
#
# It does NOT prove authorship by itself. Without a valid GPG signature,
# checksums only protect against transport corruption.
# =============================================================================
set -euo pipefail

fail() { echo "::error::[verify-release] $*" >&2; exit 1; }
info() { echo "[verify-release] $*"; }

DIR="${1:-}"
[ -n "$DIR" ] || { echo "usage: $0 <asset-dir>" >&2; exit 2; }
[ -d "$DIR" ] || fail "asset directory not found: $DIR"
cd "$DIR"

for bin in sha256sum grep awk; do
  command -v "$bin" >/dev/null 2>&1 || fail "required binary missing: $bin"
done
PYTHON_BIN="${PYTHON:-}"
if [ -z "$PYTHON_BIN" ]; then
  for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1 \
      && "$candidate" -c 'import zipfile, hashlib' >/dev/null 2>&1; then
      PYTHON_BIN="$candidate"
      break
    fi
  done
fi
[ -n "$PYTHON_BIN" ] || fail "python3 is required for zip/provenance verification"

# --- required assets ---------------------------------------------------------
for f in SHA256SUMS.txt PROVENANCE.txt SOURCE-OFFER.txt SIGNING.txt; do
  [ -s "$f" ] || fail "missing or empty required asset: $f"
done

shopt -s nullglob
ZIPS=(Peridot-Kernel-*.zip)
IMGS=(*.img)
shopt -u nullglob
[ "${#ZIPS[@]}" -eq 1 ] || fail "expected exactly 1 Peridot-Kernel-*.zip, found ${#ZIPS[@]}"
[ "${#IMGS[@]}" -eq 0 ] || fail "boot/image assets must not be released (unsigned, no AVB footer): ${IMGS[*]}"
ZIP="${ZIPS[0]}"
[ -s "$ZIP" ] || fail "zip is empty: $ZIP"
info "flashable zip: $ZIP ($(stat -c%s "$ZIP" 2>/dev/null || echo '?') bytes)"

# --- checksum manifest -------------------------------------------------------
sha256sum -c SHA256SUMS.txt >/dev/null || fail "SHA256SUMS.txt verification failed"
info "SHA256SUMS.txt verified ($(wc -l < SHA256SUMS.txt) entries)"

# Coverage: every asset (except the manifest and its signature) is listed.
COVERED=$(mktemp)
awk '{print $2}' SHA256SUMS.txt | sed 's/^\*//' | sort > "$COVERED"
while IFS= read -r asset; do
  case "$asset" in
    SHA256SUMS.txt|SHA256SUMS.txt.asc) continue ;;
  esac
  grep -Fxq "$asset" "$COVERED" || fail "asset ${asset} exists but is not covered by SHA256SUMS.txt"
done < <(find . -maxdepth 1 -type f -printf '%f\n' | sort)
grep -Fxq "$ZIP" "$COVERED" || fail "SHA256SUMS.txt does not cover $ZIP"
rm -f "$COVERED"
info "all assets covered by SHA256SUMS.txt"

# --- provenance manifest values ---------------------------------------------
grep -q '^format: flavenz-kernel-provenance-v1$' PROVENANCE.txt || fail "unexpected provenance format"
REL_TAG=$(grep '^release_tag: ' PROVENANCE.txt | awk '{print $2}')
REPO_COMMIT=$(grep '^repo_commit: ' PROVENANCE.txt | awk '{print $2}')
PROV_IMAGE_SHA=$(grep '^image_sha256: ' PROVENANCE.txt | awk '{print $2}')
LOCALVERSION=$(grep '^localversion: ' PROVENANCE.txt | awk '{print $2}')
KERNEL_RELEASE=$(grep '^kernel_release: ' PROVENANCE.txt | awk '{print $2}')

[ -n "$REL_TAG" ] || fail "provenance missing release_tag"
[ -n "$KERNEL_RELEASE" ] || fail "provenance missing kernel_release"
[ -n "$LOCALVERSION" ] || fail "provenance missing localversion"
printf '%s' "$REPO_COMMIT" | grep -Eq '^[0-9a-f]{40}$' || fail "provenance repo_commit is not a 40-char SHA"
printf '%s' "$PROV_IMAGE_SHA" | grep -Eq '^[0-9a-f]{64}$' || fail "provenance image_sha256 is not a sha256"
case "$KERNEL_RELEASE" in
  *"${LOCALVERSION}") : ;;
  *) fail "kernel_release '$KERNEL_RELEASE' does not end with localversion '$LOCALVERSION'" ;;
esac

# --- zip contents + provenance/Image consistency (python zipfile) -----------
PROV_IMAGE_SHA="$PROV_IMAGE_SHA" "$PYTHON_BIN" - "$ZIP" PROVENANCE.txt <<'PY'
import hashlib
import os
import sys
import zipfile

zip_path, prov_path = sys.argv[1], sys.argv[2]
prov_bytes = open(prov_path, "rb").read()
expected_image_sha = os.environ["PROV_IMAGE_SHA"]

with zipfile.ZipFile(zip_path) as zf:
    names = set(zf.namelist())
    for entry in ("anykernel.sh", "LICENSE", "LICENSE.txt", "PROVENANCE.txt", "SOURCE-OFFER.txt", "Image"):
        assert entry in names, f"{entry} missing from flashable zip"
    license_text = zf.read("LICENSE").decode("utf-8", "replace")
    assert len(license_text) > 10000, "LICENSE inside zip is too small to be GPL-2.0 text"
    assert "GNU GENERAL PUBLIC LICENSE" in license_text, "LICENSE inside zip is not the GPL text"
    offer = zf.read("SOURCE-OFFER.txt").decode("utf-8", "replace")
    assert "complete corresponding source" in offer, "SOURCE-OFFER.txt lacks the GPL source offer"
    assert zf.read("PROVENANCE.txt") == prov_bytes, "PROVENANCE.txt inside zip differs from the asset"
    image = zf.read("Image")
    image_sha = hashlib.sha256(image).hexdigest()
    assert image_sha == expected_image_sha, f"Image sha256 {image_sha} != provenance {expected_image_sha}"
print(f"[verify-release] zip contents OK; Image sha256 matches provenance: {expected_image_sha}")
PY

# --- signing status consistency ---------------------------------------------
if [ -f SHA256SUMS.txt.asc ]; then
  command -v gpg >/dev/null 2>&1 || fail "SHA256SUMS.txt.asc present but gpg is not available"
  gpg --verify SHA256SUMS.txt.asc SHA256SUMS.txt >/dev/null 2>&1 \
    || fail "GPG signature SHA256SUMS.txt.asc does not verify"
  grep -q '^Signing status: SIGNED' SIGNING.txt \
    || fail "signature present but SIGNING.txt does not say SIGNED"
  info "GPG signature verified"
else
  grep -q '^Signing status: UNSIGNED$' SIGNING.txt \
    || fail "no signature asset and SIGNING.txt does not say UNSIGNED (refusing to pretend it is signed)"
  info "unsigned release: SIGNING.txt correctly states UNSIGNED"
fi

# --- summary -----------------------------------------------------------------
info "OK: ${REL_TAG}"
info "  kernel_release : ${KERNEL_RELEASE}"
info "  localversion   : ${LOCALVERSION}"
info "  repo_commit    : ${REPO_COMMIT}"
info "  zip            : ${ZIP}"
info "  signing        : $(grep '^Signing status: ' SIGNING.txt)"
