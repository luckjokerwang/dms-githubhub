#!/usr/bin/env bash
# Fetch GitHub user info, PRs, Issues, and Notifications using gh CLI
set -eo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v gh >/dev/null 2>&1; then
    printf '{"authenticated":false,"reason":"gh_not_installed","user":null,"prs":[],"review_requested":[],"issues":[],"notifications":[],"unread_count":0}\n'
    exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
    printf '{"authenticated":false,"reason":"not_logged_in","user":null,"prs":[],"review_requested":[],"issues":[],"notifications":[],"unread_count":0}\n'
    exit 0
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

(
    timeout 5s gh api user 2>/dev/null > "$tmp_dir/user.json" || echo '{}' > "$tmp_dir/user.json"
) &
(
    timeout 6s gh search prs --author=@me --state=open --limit=10 --json number,title,repository,url,createdAt 2>/dev/null > "$tmp_dir/prs.json" || echo '[]' > "$tmp_dir/prs.json"
) &
(
    timeout 6s gh search prs --review-requested=@me --state=open --limit=10 --json number,title,repository,url,createdAt 2>/dev/null > "$tmp_dir/reviews.json" || echo '[]' > "$tmp_dir/reviews.json"
) &
(
    timeout 6s gh search issues --involves=@me --state=open --limit=10 --json number,title,repository,url,createdAt 2>/dev/null > "$tmp_dir/issues.json" || echo '[]' > "$tmp_dir/issues.json"
) &
(
    timeout 6s gh api notifications 2>/dev/null > "$tmp_dir/notifications.json" || echo '[]' > "$tmp_dir/notifications.json"
) &

wait

# Download avatar to assets cache in background if url exists
avatar_url=$(jq -r '.avatar_url // ""' "$tmp_dir/user.json" 2>/dev/null || true)
if [ -n "$avatar_url" ]; then
    ( curl -s -m 5 "$avatar_url" -o "$DIR/../assets/avatar.png" 2>/dev/null || true ) &
fi

jq -c -n \
  --slurpfile user "$tmp_dir/user.json" \
  --slurpfile prs "$tmp_dir/prs.json" \
  --slurpfile reviews "$tmp_dir/reviews.json" \
  --slurpfile issues "$tmp_dir/issues.json" \
  --slurpfile notifications "$tmp_dir/notifications.json" \
  '
    ($user[0] // {}) as $u |
    (if ($prs[0] | type) == "array" then $prs[0] else [] end) as $p |
    (if ($reviews[0] | type) == "array" then $reviews[0] else [] end) as $r |
    (if ($issues[0] | type) == "array" then $issues[0] else [] end) as $i |
    (if ($notifications[0] | type) == "array" then $notifications[0] else [] end) as $n |

    # 1. Open Review Requested PRs
    [ $r[] | {
        number: .number,
        title: .title,
        repo: (.repository.nameWithOwner // .repository.name // ""),
        url: .url,
        createdAt: (.createdAt // ""),
        isReviewRequested: true
    } ] as $rev_prs |

    # 2. Open Author PRs
    [ $p[] | {
        number: .number,
        title: .title,
        repo: (.repository.nameWithOwner // .repository.name // ""),
        url: .url,
        createdAt: (.createdAt // ""),
        isReviewRequested: false
    } ] as $auth_prs |

    # Merge open PRs (review-requested first, then author)
    ([ $rev_prs[], $auth_prs[] ] | unique_by(.repo + "#" + (.number|tostring))) as $final_prs |

    # 3. Open Issues (active & involving user)
    [ $i[] | {
        number: .number,
        title: .title,
        repo: (.repository.nameWithOwner // .repository.name // ""),
        url: .url,
        createdAt: (.createdAt // "")
    } ] as $final_issues |

    {
      authenticated: ($u.login != null and $u.login != ""),
      reason: (if ($u.login != null and $u.login != "") then "ok" else "auth_failed" end),
      user: {
        login: ($u.login // ""),
        name: ($u.name // $u.login // ""),
        avatar_url: ($u.avatar_url // ""),
        public_repos: ($u.public_repos // 0),
        followers: ($u.followers // 0)
      },
      prs: $final_prs,
      review_requested: $rev_prs,
      issues: $final_issues,
      unread_count: ($n | length)
    }
  '
