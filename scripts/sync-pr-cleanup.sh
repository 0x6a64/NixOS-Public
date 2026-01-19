#!/usr/bin/env bash
# sync-pr-cleanup.sh
# Clean up stale sync PRs for public repository synchronization
# Interactive script to merge newest PR and close/delete stale ones

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 [OPTIONS]

Clean up stale sync PRs targeting public-staging branch.

OPTIONS:
    -h, --help      Show this help
    -l, --list      List sync PRs without taking action
    -y, --yes       Skip confirmations (auto-yes)

EXAMPLES:
    $0              # Interactive cleanup
    $0 --list       # Just list PRs
    $0 -y           # Auto-confirm all actions

EOF
    exit "${1:-0}"
}

check_auth() {
    if ! gh auth status &>/dev/null; then
        echo -e "${RED}Error: Not authenticated with GitHub CLI${NC}"
        echo "Please run: gh auth login"
        exit 1
    fi
}

get_repo_info() {
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || {
        echo -e "${RED}Error: Not in a git repository or no remote configured${NC}"
        exit 1
    }
}

confirm() {
    local prompt="$1"
    if [ "$AUTO_YES" = true ]; then
        echo -e "$prompt ${GREEN}(auto-yes)${NC}"
        return 0
    fi
    read -rp "$prompt (Y/n): " choice
    choice=${choice:-y}
    [[ "$choice" =~ ^[yY]$ ]]
}

list_prs() {
    echo -e "${BLUE}Open Sync PRs targeting public-staging:${NC}"
    echo

    if [ "$PR_COUNT" -eq 0 ]; then
        echo -e "${GREEN}No sync PRs found${NC}"
        return
    fi

    echo "$SORTED_PRS" | jq -r '.[] | "  #\(.number | tostring | . + " " * (5 - length)) \(.headRefName | . + " " * (35 - length)) \(.createdAt)"'
    echo
    echo -e "Total: ${CYAN}$PR_COUNT${NC} PR(s)"
    echo -e "Newest: ${GREEN}#$NEWEST_NUM${NC} ($NEWEST_BRANCH)"
}

main() {
    echo -e "${BLUE}Sync PR Cleanup Tool${NC}"
    echo

    check_auth
    get_repo_info

    echo -e "Repository: ${CYAN}$REPO${NC}"
    echo

    # Get open PRs targeting public-staging from sync/* branches
    PRS=$(gh pr list --base public-staging --state open --json number,title,headRefName,createdAt,url 2>/dev/null || echo "[]")

    # Filter to sync/* branches only
    SYNC_PRS=$(echo "$PRS" | jq '[.[] | select(.headRefName | startswith("sync/"))]')
    PR_COUNT=$(echo "$SYNC_PRS" | jq 'length')

    if [ "$PR_COUNT" -eq 0 ]; then
        echo -e "${GREEN}No sync PRs found targeting public-staging${NC}"
        cleanup_branches
        exit 0
    fi

    # Sort by createdAt (newest first)
    SORTED_PRS=$(echo "$SYNC_PRS" | jq 'sort_by(.createdAt) | reverse')

    NEWEST_PR=$(echo "$SORTED_PRS" | jq '.[0]')
    NEWEST_NUM=$(echo "$NEWEST_PR" | jq -r '.number')
    NEWEST_BRANCH=$(echo "$NEWEST_PR" | jq -r '.headRefName')

    if [ "$LIST_ONLY" = true ]; then
        list_prs
        exit 0
    fi

    list_prs
    echo

    # Step 1: Merge newest PR
    if confirm "Merge PR #$NEWEST_NUM (newest)?"; then
        echo -e "${GREEN}Merging PR #$NEWEST_NUM...${NC}"
        if gh pr merge "$NEWEST_NUM" --merge; then
            echo -e "${GREEN}PR #$NEWEST_NUM merged successfully${NC}"
        else
            echo -e "${RED}Failed to merge PR #$NEWEST_NUM${NC}"
        fi
    else
        echo "Skipping merge"
    fi
    echo

    # Step 2: Close stale PRs
    if [ "$PR_COUNT" -gt 1 ]; then
        echo -e "${BLUE}Closing stale PRs...${NC}"

        STALE_PRS=$(echo "$SORTED_PRS" | jq '.[1:]')
        STALE_COUNT=$(echo "$STALE_PRS" | jq 'length')

        for i in $(seq 0 $((STALE_COUNT - 1))); do
            STALE_PR=$(echo "$STALE_PRS" | jq ".[$i]")
            STALE_NUM=$(echo "$STALE_PR" | jq -r '.number')
            STALE_BRANCH=$(echo "$STALE_PR" | jq -r '.headRefName')

            if confirm "Close stale PR #$STALE_NUM ($STALE_BRANCH)?"; then
                if gh pr close "$STALE_NUM"; then
                    echo -e "${GREEN}PR #$STALE_NUM closed${NC}"
                else
                    echo -e "${RED}Failed to close PR #$STALE_NUM${NC}"
                fi
            fi
        done
        echo
    fi

    cleanup_branches
}

cleanup_branches() {
    echo -e "${BLUE}Checking for leftover sync/* branches...${NC}"

    # Get remote sync branches using git directly
    git fetch --prune origin &>/dev/null
    REMOTE_BRANCHES=$(git branch -r | grep 'origin/sync/' | sed 's|origin/||' | xargs)

    if [ -z "$REMOTE_BRANCHES" ]; then
        echo -e "${GREEN}No sync/* branches found${NC}"
    else
        echo "Found sync/* branches:"
        for branch in $REMOTE_BRANCHES; do
            echo "  $branch"
        done
        echo

        for branch in $REMOTE_BRANCHES; do
            if [ -n "$branch" ]; then
                if confirm "Delete branch '$branch'?"; then
                    if git push origin --delete "$branch" 2>/dev/null; then
                        echo -e "${GREEN}Branch '$branch' deleted${NC}"
                    else
                        echo -e "${RED}Failed to delete branch '$branch'${NC}"
                    fi
                fi
            fi
        done
    fi

    echo
    echo -e "${GREEN}Cleanup complete!${NC}"
}

# Parse arguments
LIST_ONLY=false
AUTO_YES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -h|--help)
            usage 0
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            usage 1
            ;;
        *)
            echo -e "${RED}Unknown argument: $1${NC}"
            usage 1
            ;;
    esac
done

main "$@"
