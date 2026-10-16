#!/bin/bash
# Usage: branch-in-volo.sh <slot folder> <scope file list> <concept regex> [since YYYY-MM-DD]
# Read-only. Ranks remote branches not yet in origin/retepostale by how much they touch the
# task's scope: files in common, and diff lines mentioning the task's concepts.
# Output (TSV, best first): files_in_common  concept_lines  branch  last_commit  commits_ahead
cartella="$1"; ambito="$2"; concetti="$3"
dal="${4:-$(date -d '150 days ago' +%F)}"
R=origin/retepostale
cd "$cartella" || exit 1
sort -u "$ambito" > /tmp/vp-ambito-sorted.txt
for b in $(git for-each-ref --format='%(refname:short)' --sort=-committerdate refs/remotes/origin); do
    [ "$b" = "$R" ] && continue
    [ "$b" = "origin/HEAD" ] && continue
    d=$(git log -1 --format=%cs "$b")
    [[ "$d" < "$dal" ]] && break
    case "$b" in *prod*|*main*|*snapshot*|*produzione*|*master*) continue;; esac
    c=$(git rev-list --count "$R..$b")
    [ "$c" = 0 ] && continue
    [ "$c" -gt 150 ] && continue
    k=$(git diff --name-only "$R...$b" 2>/dev/null | sort -u | comm -12 - /tmp/vp-ambito-sorted.txt | wc -l)
    s=$(git diff "$R...$b" 2>/dev/null | grep -c -i -E "^[+-].*($concetti)")
    if [ "$k" -gt 0 ] || [ "$s" -gt 0 ]; then
        printf '%s\t%s\t%s\t%s\t%s\n' "$k" "$s" "$b" "$d" "$c"
    fi
done | sort -t$'\t' -k1,1nr -k2,2nr
