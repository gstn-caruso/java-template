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

main() {
  parse_args "$@"
  validate_required_arguments
}

main "$@"
