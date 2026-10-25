#!/usr/bin/env bash
set -euo pipefail

repo_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
required_files=(
  README.md
  SKILL.md
  LICENSE
  NOTICE
  ACKNOWLEDGMENTS.md
  CONTRIBUTING.md
  SECURITY.md
  CODE_OF_CONDUCT.md
  docs/public-preview.md
  skills/gsd/precheck-gate.md
  skills/gsd/research-phase.md
  examples/phase-001/Phase-001.md
  examples/phase-001/Phase-001.specification.json
)

for path in "${required_files[@]}"; do
  test -f "$repo_root/$path" || { echo "MISSING: $path"; exit 1; }
done

version="$(sed -n 's/^version: *//p' "$repo_root/SKILL.md" | head -1)"
test "$version" = "3.4.0-preview.1" || {
  echo "UNEXPECTED SKILL VERSION: $version"
  exit 1
}

python3 - "$repo_root/examples/phase-001/Phase-001.specification.json" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)

required = {"schema", "phase_id", "specification_id", "version", "requirements", "acceptance_criteria", "verification", "phase_gate"}
missing = sorted(required - data.keys())
if missing:
    raise SystemExit(f"MISSING SPEC FIELDS: {', '.join(missing)}")
if data["schema"] != "phase-specification.v1":
    raise SystemExit(f"UNEXPECTED SCHEMA: {data['schema']}")
print("example specification: valid fixture shape")
PY

public_paths=(README.md SKILL.md CONTRIBUTING.md SECURITY.md NOTICE docs/public-preview.md skills examples)
forbidden='(/opt/|sentinel-vault|SENTINEL|bms-intelligence|Infisical|OmniRoute|OMNIROUTE|OMNIROUTE_API_KEY)'
if rg -n -i "$forbidden" "${public_paths[@]/#/$repo_root/}"; then
  echo "FORBIDDEN INTERNAL REFERENCE FOUND"
  exit 1
fi

if rg -n -e '-----BEGIN (RSA|EC|OPENSSH|PRIVATE) KEY-----|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{20,}' "${public_paths[@]/#/$repo_root/}"; then
  echo "POSSIBLE CREDENTIAL MATERIAL FOUND"
  exit 1
fi

echo "public package validation: PASS"
echo "skill version: $version"
echo "required files: ${#required_files[@]} present"
