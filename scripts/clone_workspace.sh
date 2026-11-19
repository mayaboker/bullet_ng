#!/usr/bin/env bash
set -euo pipefail

projects=(
    bullet_drone bullet_render bullet_app beta_client
    bullet_view bullet_perception los_tracking bullet_visual
)

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

if (( $# > 1 )); then
    printf 'Usage: %s [tag]\n' "${0##*/}" >&2
    exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
workspace_root=$(cd -- "$script_dir/.." && pwd -P)
expected_root=$(realpath -m -- "${HOME:?}/workspaces/bullet_ng")
[[ $workspace_root == "$expected_root" ]] || fail "Run this script from $expected_root"
[[ $(git -C "$workspace_root" rev-parse --show-toplevel) == "$workspace_root" ]] ||
    fail 'The bullet_ng directory must be a Git checkout'

if (( $# == 0 )); then
    mapfile -t tags < <(git -C "$workspace_root" tag --list --sort=version:refname)
    if (( ${#tags[@]} == 0 )); then
        printf 'No tags available\n'
    else
        printf '%s\n' "${tags[@]}"
    fi
    exit 0
fi

tag=$1
git check-ref-format "refs/tags/$tag" >/dev/null 2>&1 || fail "Invalid tag name: $tag"
branch="workspace/$tag"
git check-ref-format "refs/heads/$branch" >/dev/null 2>&1 || fail "Invalid branch name: $branch"
git -C "$workspace_root" rev-parse --verify --quiet "refs/tags/$tag^{commit}" >/dev/null ||
    fail "Tag $tag is not defined in bullet_ng"

projects_dir="${HOME}/projects"
for project in "${projects[@]}"; do
    destination="$projects_dir/$project"
    [[ ! -e $destination && ! -L $destination ]] || fail "Destination already exists: $destination"
done

declare -A tag_commits=()
for project in "${projects[@]}"; do
    url="https://github.com/mayaboker/$project.git"
    refs=$(GIT_TERMINAL_PROMPT=0 git ls-remote "$url" "refs/tags/$tag" "refs/tags/$tag^{}") ||
        fail "Could not inspect tags in $url"
    direct=''
    peeled=''
    while read -r commit ref; do
        case "$ref" in
            "refs/tags/$tag") direct=$commit ;;
            "refs/tags/$tag^{}") peeled=$commit ;;
        esac
    done <<< "$refs"
    [[ -n $direct ]] || fail "Tag $tag is missing in $project"
    tag_commits[$project]=${peeled:-$direct}
done

mkdir -p -- "$projects_dir"
stage=$(mktemp -d "$projects_dir/.bullet-clone.XXXXXXXX")
promoted=()
cleanup() {
    result=$?
    if (( result != 0 )); then
        for project in "${promoted[@]}"; do
            rm -rf -- "$projects_dir/$project"
        done
    fi
    rm -rf -- "$stage"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for project in "${projects[@]}"; do
    url="https://github.com/mayaboker/$project.git"
    checkout="$stage/$project"
    git clone --no-checkout "$url" "$checkout"
    git -C "$checkout" switch --detach "refs/tags/$tag"
    [[ $(git -C "$checkout" rev-parse HEAD) == "${tag_commits[$project]}" ]] ||
        fail "Tag $tag resolved to an unexpected commit in $project"
    git -C "$checkout" switch -c "$branch"
done

for project in "${projects[@]}"; do
    destination="$projects_dir/$project"
    [[ ! -e $destination && ! -L $destination ]] || fail "Destination appeared during cloning: $destination"
    mv -n -T -- "$stage/$project" "$destination"
    [[ ! -e $stage/$project ]] || fail "Could not install $project at $destination"
    promoted+=("$project")
    printf 'Installed %s at %s (%s)\n' "$project" "$destination" "$branch"
done
