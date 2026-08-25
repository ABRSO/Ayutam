#!/usr/bin/env bash
# Verify Android release APKs are signed with the pinned Ayutam certificate.
# Usage: tool/verify_android_release_apks.sh <apk> [<apk> ...]
#
# The expected SHA-256 comes from android/release-cert.sha256 (checked in),
# never from the JKS used to sign the APKs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PIN_FILE="${ROOT}/android/release-cert.sha256"

if [[ "$#" -lt 1 ]]; then
  echo "usage: $0 <apk> [<apk> ...]" >&2
  exit 2
fi

normalize() {
  tr -d '[:space:]:' | tr '[:upper:]' '[:lower:]'
}

if [[ ! -f "${PIN_FILE}" ]]; then
  echo "error: missing pin file ${PIN_FILE}" >&2
  exit 1
fi

# Strip CR so Windows checkouts still parse; never read the signing JKS.
EXPECTED_RAW="$(tr -d '\r' < "${PIN_FILE}" | grep -E '^[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2})+$' | head -n 1 || true)"
EXPECTED="$(printf '%s' "${EXPECTED_RAW}" | normalize)"
if [[ -z "${EXPECTED}" || "${#EXPECTED}" -ne 64 ]]; then
  echo "error: android/release-cert.sha256 has no valid SHA-256 fingerprint" >&2
  exit 1
fi

find_apksigner() {
  local sdk candidate dir newest
  sdk="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  if [[ -z "${sdk}" ]]; then
    for candidate in \
      "${HOME}/Android/Sdk" \
      "${LOCALAPPDATA:-}/Android/Sdk" \
      /usr/local/lib/android/sdk \
      /opt/android-sdk; do
      if [[ -n "${candidate}" && -d "${candidate}/build-tools" ]]; then
        sdk="${candidate}"
        break
      fi
    done
  fi
  if [[ -n "${sdk}" && -d "${sdk}/build-tools" ]]; then
    newest=""
    while IFS= read -r dir; do
      [[ -d "${dir}" ]] || continue
      if [[ -x "${dir}/apksigner" || -f "${dir}/apksigner" ]]; then
        newest="${dir}/apksigner"
      elif [[ -f "${dir}/apksigner.bat" ]]; then
        newest="${dir}/apksigner.bat"
      fi
    done < <(find "${sdk}/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V)
    if [[ -n "${newest}" ]]; then
      printf '%s\n' "${newest}"
      return 0
    fi
  fi
  if command -v apksigner >/dev/null 2>&1; then
    command -v apksigner
    return 0
  fi
  return 1
}

APKSIGNER="$(find_apksigner || true)"
if [[ -z "${APKSIGNER}" ]]; then
  echo "error: apksigner not found (set ANDROID_HOME / ANDROID_SDK_ROOT)" >&2
  exit 1
fi

echo "Using apksigner: ${APKSIGNER}"
echo "Expected signer SHA-256: ${EXPECTED}"

first=""
for apk in "$@"; do
  if [[ ! -f "${apk}" ]]; then
    echo "error: missing APK ${apk}" >&2
    exit 1
  fi
  certs="$("${APKSIGNER}" verify --print-certs -- "${apk}")"
  actual="$(printf '%s\n' "${certs}" \
    | tr -d '\r' \
    | grep -i 'SHA-256 digest:' \
    | head -n 1 \
    | sed 's/.*SHA-256 digest:[[:space:]]*//' \
    | normalize)"
  if [[ -z "${actual}" || "${#actual}" -ne 64 ]]; then
    echo "error: could not parse signer SHA-256 from ${apk}" >&2
    printf '%s\n' "${certs}" >&2
    exit 1
  fi
  if [[ "${actual}" != "${EXPECTED}" ]]; then
    echo "error: ${apk} signer SHA-256 ${actual} does not match pinned ${EXPECTED}" >&2
    exit 1
  fi
  if [[ -z "${first}" ]]; then
    first="${actual}"
  elif [[ "${actual}" != "${first}" ]]; then
    echo "error: ${apk} signer ${actual} differs from ${first}" >&2
    exit 1
  fi
  echo "OK $(basename "${apk}") SHA-256=${actual}"
done
