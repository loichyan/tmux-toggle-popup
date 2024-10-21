#!/usr/bin/env bash

### Create or update a GitHub release.
###
### USAGE:
###
###   GIT_CLIFF_TAG="<tag>" GIT_CLIFF_SUMMARY="<summary>" update-release.sh

set -exo pipefail

GIT_CLIFF_TAG="${GIT_CLIFF_TAG:-${GITHUB_HEAD_REF#release/}}"
# normalize CRLF
GIT_CLIFF_SUMMARY="${GIT_CLIFF_SUMMARY//$'\r'/}"

# update CHANGELOG based on the main branch
git checkout -B release "origin/$GITHUB_HEAD_REF"
git checkout "origin/$GITHUB_BASE_REF" -- CHANGELOG.md
# TODO: use --from-context <https://github.com/orhun/git-cliff/pull/920>
git cliff --unreleased --prepend=CHANGELOG.md
git cliff --unreleased --strip=header --output=SUMMARY.md

# commit CHANGELOG
git add CHANGELOG.md
if git commit -m "chore(release): update CHANGELOG" &>/dev/null; then
	git push origin "HEAD:$GITHUB_HEAD_REF"
fi

# create a new release or update the existing one
if gh release view "$GIT_CLIFF_TAG" &>/dev/null; then
	command='edit'
else
	command='create'
fi
gh release "$command" "$GIT_CLIFF_TAG" \
	--target="$GITHUB_BASE_REF" \
	--draft=true \
	--title="Release $GIT_CLIFF_TAG" \
	--notes-file=SUMMARY.md
