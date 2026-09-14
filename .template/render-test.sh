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

rutas_renombradas_con_placeholders() {
  current="rutas renombradas con placeholders"
  local scratch
  scratch=$(copy_repo_to_scratch)
  render_holy_wars_sample_in "$scratch" >/dev/null 2>&1
  local java_file="$scratch/game/src/main/java/holywars/game/HolyWarsGame.java"
  [[ -f $java_file ]] && pass || fail "no existe $java_file"
  grep -q 'class HolyWarsGame' "$java_file" 2>/dev/null && pass || fail "la clase no se declaro HolyWarsGame"
  [[ -f "$scratch/game/src/deb/holy-wars" ]] && pass || fail "falta el launcher renombrado"
  [[ -f "$scratch/game/src/deb/holy-wars.desktop" ]] && pass || fail "falta el .desktop renombrado"
  [[ -f "$scratch/game/src/deb/icons/holy-wars.svg" ]] && pass || fail "falta el icono renombrado"
  rm -rf "$scratch"
}

rutas_renombradas_con_placeholders

pom_raiz_y_releaserc_quedan_coherentes() {
  current="pom raiz y releaserc quedan coherentes"
  local scratch
  scratch=$(copy_repo_to_scratch)
  render_holy_wars_sample_in "$scratch" >/dev/null 2>&1
  local pom="$scratch/pom.xml"
  grep -q '<version>0.0.0-SNAPSHOT</version>' "$pom" 2>/dev/null && pass || fail "version incorrecta en pom.xml"
  grep -q '<module>game</module>' "$pom" 2>/dev/null && pass || fail "module game ausente en pom.xml"
  grep -q '<artifactId>holy-wars-parent</artifactId>' "$pom" 2>/dev/null && pass || fail "artifactId incorrecto en pom.xml"
  grep -q '<groupId>io.github.gstncaruso</groupId>' "$pom" 2>/dev/null && pass || fail "groupId incorrecto en pom.xml"
  grep -q '<artifactId>holy-wars-domain</artifactId>' "$scratch/game/pom.xml" 2>/dev/null && pass || fail "game/pom.xml no referencia holy-wars-domain"
  local releaserc="$scratch/.releaserc.json"
  grep -q '"@semantic-release/git"' "$releaserc" 2>/dev/null && fail "releaserc tiene @semantic-release/git en modo tag-only" || pass
  grep -q 'game/target/holy-wars_\*_all.deb' "$releaserc" 2>/dev/null && pass || fail "asset del releaserc incorrecto"
  rm -rf "$scratch"
}

pom_raiz_y_releaserc_quedan_coherentes

defaults_se_derivan_del_slug_y_el_owner() {
  current="defaults se derivan del slug y el owner"
  local scratch out status
  scratch=$(copy_repo_to_scratch)
  out=$(render_in "$scratch" --slug my-cool-app --name "My Cool App" \
    --description "d" --owner some-owner --flavor libgdx --release tag-only \
    --author "Someone" --email someone@example.com --year 2030 2>&1)
  status=$?
  check "exit status" 0 "$status"
  [[ -f "$scratch/game/src/main/java/mycoolapp/game/MyCoolAppGame.java" ]] \
    && pass || fail "no existe el java con paquete/clase derivados: $out"
  grep -q '<groupId>io.github.someowner</groupId>' "$scratch/pom.xml" 2>/dev/null \
    && pass || fail "group-id derivado incorrecto"
  grep -q 'Copyright (c) 2030 Someone' "$scratch/LICENSE" 2>/dev/null \
    && pass || fail "LICENSE no tiene el year/author dados"
  rm -rf "$scratch"
}

defaults_se_derivan_del_slug_y_el_owner

valores_con_caracteres_especiales_quedan_literales() {
  current="valores con caracteres especiales quedan literales"
  local scratch out status
  scratch=$(copy_repo_to_scratch)
  out=$(render_in "$scratch" --slug weird-app --name "Weird App" \
    --description 'A/B & C | D' --owner gstn-caruso --flavor libgdx --release tag-only \
    --author "A" --email a@example.com 2>&1)
  status=$?
  check "exit status" 0 "$status"
  grep -qF 'A/B & C | D' "$scratch/pom.xml" 2>/dev/null && pass || fail "descripcion no literal en pom.xml: $out"
  grep -qF 'A/B & C | D' "$scratch/README.md" 2>/dev/null && pass || fail "descripcion no literal en README.md"
  rm -rf "$scratch"
}

valores_con_caracteres_especiales_quedan_literales

unresolved_placeholder_fails_with_exit_1() {
  current="unresolved placeholder fails with exit 1"
  local scratch err status
  scratch=$(copy_repo_to_scratch)
  echo '{{orphan}}' >> "$scratch/.template/common/.tcr"
  err=$(render_holy_wars_sample_in "$scratch" 2>&1 1>/dev/null)
  status=$?
  check "exit status" 1 "$status"
  echo "$err" | grep -q '\.tcr' && pass || fail "stderr no nombro el archivo con el placeholder: $err"
  rm -rf "$scratch"
}

unresolved_placeholder_fails_with_exit_1

printf '\n%d ok, %d fallando\n' "$passed" "$failed"
[[ $failed -eq 0 ]]
