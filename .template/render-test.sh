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

flavor_inexistente_falla() {
  current="flavor inexistente falla"
  local scratch status
  scratch=$(copy_repo_to_scratch)
  render_in "$scratch" --slug x --name X --description d --owner o \
    --flavor noexiste --release tag-only >/dev/null 2>&1
  status=$?
  check "exit status" 2 "$status"
  rm -rf "$scratch"
}

release_inexistente_falla() {
  current="release inexistente falla"
  local scratch status
  scratch=$(copy_repo_to_scratch)
  render_in "$scratch" --slug x --name X --description d --owner o \
    --flavor libgdx --release noexiste >/dev/null 2>&1
  status=$?
  check "exit status" 2 "$status"
  rm -rf "$scratch"
}

flavor_inexistente_falla
release_inexistente_falla

render_completo_arma_el_layout_esperado() {
  current="render completo arma el layout esperado"
  local scratch out status
  scratch=$(copy_repo_to_scratch)
  out=$(render_holy_wars_sample_in "$scratch" 2>&1)
  status=$?
  check "exit status" 0 "$status"
  check "sin placeholders sin resolver" "" "$(grep -rlE '\{\{[a-z_]+\}\}' "$scratch" 2>/dev/null | tr '\n' ' ' | sed 's/ *$//')"
  [[ -d "$scratch/.template" ]] && fail ".template sigue existiendo" || pass
  [[ -f "$scratch/.github/workflows/template-ci.yml" ]] && fail "template-ci.yml sigue existiendo" || pass
  [[ -f "$scratch/.github/workflows/ci.yml" ]] && pass || fail "ci.yml no existe: $out"
  grep -q '${{ runner.os }}' "$scratch/.github/workflows/ci.yml" 2>/dev/null && pass || fail "ci.yml perdio \${{ runner.os }}"
  [[ -d "$scratch/game" ]] && pass || fail "game/ no existe"
  check ".tcr" "mvn -q -B test" "$(cat "$scratch/.tcr" 2>/dev/null)"
  check "README arranca con el nombre" "# Holy Wars" "$(head -n1 "$scratch/README.md" 2>/dev/null)"
  rm -rf "$scratch"
}

render_completo_arma_el_layout_esperado

printf '\n%d ok, %d fallando\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
