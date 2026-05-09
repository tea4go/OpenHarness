#!/usr/bin/env bash
set -euo pipefail

UPSTREAM_URL="https://github.com/1jehuang/jcode.git"
UPSTREAM_NAME="upstream"
UPSTREAM_BRANCH="master"
LOCAL_BRANCH="master"

info() { printf '\033[1;34m%s\033[0m\n' "$*"; }
err()  { printf '\033[1;31merror: %s\033[0m\n' "$*" >&2; exit 1; }
warn() { printf '\033[1;33mwarning: %s\033[0m\n' "$*" >&2; }

# 1. Check we're inside a git repository
git rev-parse --git-dir >/dev/null 2>&1 || err "Not inside a git repository."

# 2. Check working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    err "Working directory is not clean. Please stash or commit your changes before syncing."
fi

# 3. Check current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "$LOCAL_BRANCH" ]; then
    err "Not on '$LOCAL_BRANCH' branch (currently on '$CURRENT_BRANCH'). Run: git switch $LOCAL_BRANCH"
fi

# 4. Configure upstream remote (idempotent)
if git remote get-url "$UPSTREAM_NAME" >/dev/null 2>&1; then
    EXISTING_URL=$(git remote get-url "$UPSTREAM_NAME")
    if [ "$EXISTING_URL" != "$UPSTREAM_URL" ]; then
        err "Remote '$UPSTREAM_NAME' already exists with a different URL: $EXISTING_URL
  Expected: $UPSTREAM_URL
  Please resolve manually."
    fi
else
    info "Adding remote: $UPSTREAM_NAME -> $UPSTREAM_URL"
    git remote add "$UPSTREAM_NAME" "$UPSTREAM_URL"
fi

# 5. Fetch upstream
info "Fetching $UPSTREAM_NAME/$UPSTREAM_BRANCH..."
git --no-pager fetch "$UPSTREAM_NAME" "$UPSTREAM_BRANCH" --tags

# 6. Show commits to be merged
COMMIT_COUNT=$(git rev-list --count "$LOCAL_BRANCH".."$UPSTREAM_NAME/$UPSTREAM_BRANCH" 2>/dev/null || echo "0")

if [ "$COMMIT_COUNT" -eq 0 ]; then
    info "Local $LOCAL_BRANCH is already up to date with $UPSTREAM_NAME/$UPSTREAM_BRANCH. Nothing to sync."
    exit 0
fi

info "Found $COMMIT_COUNT new commit(s) from upstream:"
echo ""
git --no-pager log --oneline --max-count=20 "$LOCAL_BRANCH".."$UPSTREAM_NAME/$UPSTREAM_BRANCH"
if [ "$COMMIT_COUNT" -gt 20 ]; then
    echo "  ... and $((COMMIT_COUNT - 20)) more"
fi
echo ""

# 7. Prompt for confirmation
printf "Merge these %s commit(s) into local %s? [y/N] " "$COMMIT_COUNT" "$LOCAL_BRANCH"
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    info "Sync cancelled by user."
    exit 1
fi

# 8. Merge
info "Merging $UPSTREAM_NAME/$UPSTREAM_BRANCH into $LOCAL_BRANCH..."
git --no-pager merge --no-edit "$UPSTREAM_NAME/$UPSTREAM_BRANCH"
MERGE_EXIT=$?

if [ "$MERGE_EXIT" -eq 0 ]; then
    NEW_HEAD=$(git rev-parse --short HEAD)
    info "Successfully merged upstream changes."
    info "New HEAD: $NEW_HEAD"
    echo ""
    info "To push to your origin:"
    echo "  git push origin $LOCAL_BRANCH"
else
    warn "Merge failed — there are conflicts to resolve."
    echo ""
    warn "Conflicting files:"
    git --no-pager diff --name-only --diff-filter=U
    echo ""
    info "Resolve conflicts, then stage and continue:"
    echo "  git add <resolved-files>"
    echo "  git merge --continue"
    echo ""
    info "Or abort the merge:"
    echo "  git merge --abort"
    exit 1
fi
