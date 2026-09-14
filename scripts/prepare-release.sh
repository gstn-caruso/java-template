#!/usr/bin/env bash
# Invoked by @semantic-release/exec (prepareCmd) with the new version already
# decided by commit-analyzer. Sets that version on the parent, domain and
# {{app_module}} poms in CI's working tree and builds the .deb with that name;
# this script never commits anything, the release mode decides whether a
# commit-back exists.
set -euo pipefail

VERSION="$1"

mvn -B org.codehaus.mojo:versions-maven-plugin:2.22.0:set \
  -DnewVersion="${VERSION}" \
  -DprocessAllModules=true \
  -DgenerateBackupPoms=false

mvn -B -pl {{app_module}} -am package
