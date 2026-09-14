#!/usr/bin/env bash
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
passed=0
failed=0
current=""

fail() { printf 'FAIL  %s\n      %s\n' "$current" "$1"; failed=$((failed + 1)); }
pass() { passed=$((passed + 1)); }

check() {
  local what=$1 expected=$2 actual=$3
  if [[ $expected == "$actual" ]]; then pass; else fail "$what: esperado <$expected>, obtenido <$actual>"; fi
}

copy_repo_to_scratch() {
  local out
  out=$(mktemp -d)
  tar --exclude=.git -cf - -C "$REPO_ROOT" . | tar -xf - -C "$out"
  printf '%s' "$out"
}

render_in() {
  local scratch=$1
  shift
  (cd "$scratch" && bash .template/render.sh "$@")
}

render_holy_wars_sample_in() {
  local scratch=$1
  shift
  render_in "$scratch" --slug holy-wars --name "Holy Wars" \
    --description "Juego hecho con libGDX en Java 25." --owner gstn-caruso \
    --flavor libgdx --release tag-only --author "Gaston Caruso" --email gstn.caruso@gmail.com "$@"
}

sin_args_muestra_uso_y_falla() {
  current="sin args muestra uso y falla"
  local scratch err status
  scratch=$(copy_repo_to_scratch)
  err=$(render_in "$scratch" 2>&1 1>/dev/null)
  status=$?
  check "exit status" 2 "$status"
  echo "$err" | grep -qi '^Usage' && pass || fail "no imprimio usage en stderr: $err"
  rm -rf "$scratch"
}

falta_un_obligatorio_falla() {
  current="falta un obligatorio falla"
  local scratch status
  scratch=$(copy_repo_to_scratch)
  render_in "$scratch" --slug x --name X --description d --owner o --release tag-only >/dev/null 2>&1
  status=$?
  check "exit status" 2 "$status"
  rm -rf "$scratch"
}

sin_args_muestra_uso_y_falla
falta_un_obligatorio_falla

printf '\n%d ok, %d fallando\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
