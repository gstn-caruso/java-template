#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: render.sh --slug <slug> --name <name> --description <description> --owner <owner> \
                  --flavor <flavor> --release <release> \
                  [--package <package>] [--class <class>] [--group-id <group-id>] \
                  [--author <author>] [--email <email>] [--year <year>]
USAGE
}

fail_usage() {
  usage
  exit 2
}

SLUG=""
NAME=""
DESCRIPTION=""
OWNER=""
FLAVOR=""
RELEASE=""
PACKAGE=""
CLASS_NAME=""
GROUP_ID=""
AUTHOR=""
EMAIL=""
YEAR=""
APP_MODULE=""
VERSION=""

assign_option() {
  local flag=$1 value=$2
  case "$flag" in
    --slug) SLUG=$value ;;
    --name) NAME=$value ;;
    --description) DESCRIPTION=$value ;;
    --owner) OWNER=$value ;;
    --flavor) FLAVOR=$value ;;
    --release) RELEASE=$value ;;
    --package) PACKAGE=$value ;;
    --class) CLASS_NAME=$value ;;
    --group-id) GROUP_ID=$value ;;
    --author) AUTHOR=$value ;;
    --email) EMAIL=$value ;;
    --year) YEAR=$value ;;
  esac
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --slug|--name|--description|--owner|--flavor|--release|--package|--class|--group-id|--author|--email|--year)
        (( $# >= 2 )) || fail_usage
        assign_option "$1" "$2"
        shift 2
        ;;
      *)
        fail_usage
        ;;
    esac
  done
}

validate_required_arguments() {
  local required_name
  for required_name in SLUG NAME DESCRIPTION OWNER FLAVOR RELEASE; do
    [[ -n ${!required_name} ]] || fail_usage
  done
}

validate_flavor_and_release_exist() {
  [[ -d "$SCRIPT_DIR/flavors/$FLAVOR" ]] || fail_usage
  [[ -d "$SCRIPT_DIR/release/$RELEASE" ]] || fail_usage
}

package_from_slug() { printf '%s' "${1//-/}"; }

class_from_slug() {
  local slug=$1 result="" part parts
  IFS='-' read -ra parts <<< "$slug"
  for part in "${parts[@]}"; do
    result+="$(tr '[:lower:]' '[:upper:]' <<< "${part:0:1}")${part:1}"
  done
  printf '%s' "$result"
}

app_module_for_flavor() {
  case "$1" in
    libgdx) printf 'game' ;;
    *) printf 'app' ;;
  esac
}

version_for_release() {
  case "$1" in
    tag-only) printf '0.0.0-SNAPSHOT' ;;
    *) printf '0.1.0-SNAPSHOT' ;;
  esac
}

apply_defaults() {
  [[ -n $PACKAGE ]] || PACKAGE=$(package_from_slug "$SLUG")
  [[ -n $CLASS_NAME ]] || CLASS_NAME=$(class_from_slug "$SLUG")
  [[ -n $GROUP_ID ]] || GROUP_ID="io.github.$(package_from_slug "$OWNER")"
  [[ -n $AUTHOR ]] || AUTHOR=$(git config user.name 2>/dev/null || true)
  [[ -n $EMAIL ]] || EMAIL=$(git config user.email 2>/dev/null || true)
  [[ -n $YEAR ]] || YEAR=$(date +%Y)
  APP_MODULE=$(app_module_for_flavor "$FLAVOR")
  VERSION=$(version_for_release "$RELEASE")
}

sed_escape_replacement() {
  local value=$1
  value=${value//\\/\\\\}
  value=${value//&/\\&}
  printf '%s' "$value"
}

SED_EXPRESSIONS=()

build_sed_expressions() {
  local delim=$'\x01'
  local placeholder value
  for placeholder in slug name description owner package class group_id author email year app_module version; do
    case "$placeholder" in
      slug) value=$SLUG ;;
      name) value=$NAME ;;
      description) value=$DESCRIPTION ;;
      owner) value=$OWNER ;;
      package) value=$PACKAGE ;;
      class) value=$CLASS_NAME ;;
      group_id) value=$GROUP_ID ;;
      author) value=$AUTHOR ;;
      email) value=$EMAIL ;;
      year) value=$YEAR ;;
      app_module) value=$APP_MODULE ;;
      version) value=$VERSION ;;
    esac
    SED_EXPRESSIONS+=(-e "s${delim}{{${placeholder}}}${delim}$(sed_escape_replacement "$value")${delim}g")
  done
}

substitute_placeholders() {
  printf '%s' "$1" | sed "${SED_EXPRESSIONS[@]}"
}

copy_common_layer() { cp -a "$SCRIPT_DIR/common/." "$ROOT/"; }
copy_flavor_layer() { cp -a "$SCRIPT_DIR/flavors/$FLAVOR/." "$ROOT/"; }
copy_release_layer() { cp -a "$SCRIPT_DIR/release/$RELEASE/." "$ROOT/"; }

rename_placeholder_paths() {
  local path old_name new_name new_path
  while IFS= read -r path; do
    case "$path" in
      "$ROOT/.git" | "$ROOT/.git"/*) continue ;;
    esac
    old_name=$(basename "$path")
    new_name=$(substitute_placeholders "$old_name")
    if [[ $new_name != "$old_name" ]]; then
      new_path="$(dirname "$path")/$new_name"
      mv "$path" "$new_path"
    fi
  done < <(find "$ROOT" -depth)
}

replace_placeholder_contents() {
  local file
  while IFS= read -r file; do
    sed -i "${SED_EXPRESSIONS[@]}" "$file"
  done < <(grep -rl '{{' "$ROOT" --exclude-dir=.git)
}

remove_template_sources() {
  rm -rf "$SCRIPT_DIR"
  rm -f "$ROOT/.github/workflows/template-ci.yml"
}

fail_if_placeholders_remain() {
  local leftover
  leftover=$(grep -rlE '\{\{[a-z_]+\}\}' "$ROOT" --exclude-dir=.git 2>/dev/null || true)
  if [[ -n $leftover ]]; then
    echo "render.sh: placeholders sin resolver en:" >&2
    echo "$leftover" >&2
    exit 1
  fi
}

render_project() {
  apply_defaults
  build_sed_expressions
  copy_common_layer
  copy_flavor_layer
  copy_release_layer
  remove_template_sources
  rename_placeholder_paths
  replace_placeholder_contents
  fail_if_placeholders_remain
}

main() {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ROOT="$(dirname "$SCRIPT_DIR")"
  parse_args "$@"
  validate_required_arguments
  validate_flavor_and_release_exist
  render_project
}

main "$@"
