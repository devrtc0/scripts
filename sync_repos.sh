#!/usr/bin/env sh

COLORS="true"
enable_colors() {
    ALL_OFF="\e[1;0m"
    BOLD="\e[1;1m"
    GREEN="${BOLD}\e[1;32m"
    BLUE="${BOLD}\e[1;34m"

    PACMAN_COLORS='--color=always'
    PACCACHE_COLORS=''
    MAKEPKG_COLORS=''
}
info() {
    local mesg=$1; shift
    printf "${BLUE}  ->${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@"
}
error() {
    local mesg=$1; shift
    printf "${RED}==> ERROR:${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@"
}
msg() {
    local mesg=$1; shift
    printf "\n${GREEN}==>${ALL_OFF}${BOLD} ${mesg}${ALL_OFF}\n" "$@"
}
[ "$COLORS" = "true" ] && enable_colors

# **********************************************************************************
# **********************************************************************************
# **********************************************************************************


if [ $# -eq 0 ]; then
    msg "dir is requried"
    msg "usage: ./sync_repos.sh <dir>"
    exit -1
fi

if [ -z "$GH_TOKEN" ]; then
    error "env GH_TOKEN required"
    exit -1
fi

if [ -z "$GH_USER" ]; then
    error "env GH_USER required"
    exit -1
fi

API_VERSION="2022-11-28"

pacman -Qi jq >/dev/null 2>&1
if [ $? -ne 0 ]; then
    error "jq is required"
    exit -1
fi
pacman -Qi git >/dev/null 2>&1
if [ $? -ne 0 ]; then
    error "git is required"
    exit -1
fi
pacman -Qi coreutils >/dev/null 2>&1
if [ $? -ne 0 ]; then
    error "coreutils is required"
    exit -1
fi

WORKDIR=$(readlink -f $1)
if [ $? -ne 0 ]; then
    error "wrong dir name $1"
    exit -1
fi
if [ ! -d "$WORKDIR" ]; then
    error "$1 not exists"
    exit -1
fi

repos_info=$(curl -SsL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "X-GitHub-Api-Version: $API_VERSION" 'https://api.github.com/user/repos?per_page=100')
[ $? -ne 0 ] && error "repos getting" && exit -1
repos=$(echo "$repos_info" | jq -r '.[] | .ssh_url')
[ $? -ne 0 ] && error "repos parsing" && exit -1

if [ -z "$FORCE" ]; then
	FORCE=false
else
    msg "FORCE update"
	FORCE=true
fi

cd $WORKDIR
for repo in $repos
do
    date
    name=$(basename -s '.git' "$repo")
    repo_info=$(curl -SsL \
			--retry 3 \
   			--connect-timeout 10 \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $GH_TOKEN" \
            -H "X-GitHub-Api-Version: $API_VERSION" https://api.github.com/repos/$GH_USER/$name)
    [ $? -ne 0 ] && error "repo $repo getting" && exit -1
    if ! $FORCE; then
		topics=($(echo "$repo_info" | jq -r '.topics[]' | tr '\n' ' '))
	    found=false
	    for topic in "${topics[@]}"; do
	        if [ "$topic" = "backup" ]; then
	            found=true
	            break
	        fi
	    done
	    if $found; then
	        info "updating $repo"
	    else
	        info "skip updating $repo"
	        continue
	    fi
    fi
    if [ ! -d "$WORKDIR/$name" ]; then
        git clone "$repo"
        [ $? -ne 0 ] && error "$repo cloning" && exit -1
        upstream=$(echo "$repo_info" | jq -r '.parent.ssh_url')
        [ $? -ne 0 ] && error "upstream parsing for $repo" && exit -1
        if [ "null" = "$upstream" ]; then
            info "no upstream for $repo"
        else
            cd "$name"
            info "setting upstream $upstream for $repo"
            git remote add upstream "$upstream"
            cd ..
        fi
    fi
    fork=$(echo "$repo_info" | jq '.fork')
    [ $? -ne 0 ] && error "fork parsing for $repo" && exit -1
    cd "$name"
    info "pulling $name"
    git pull
    [ $? -ne 0 ] && error "pull failed: $repo" && exit -1
    if [ "true" = "$fork" ]; then
    	info "fetching $name upstream"
        git fetch upstream
        [ $? -ne 0 ] && error "fetch failed: $repo" && exit -1
        branch=$(git branch --show-current)
        [ $? -ne 0 ] && error "branch getting failed: $repo" && exit -1
        git diff --exit-code "$branch" "upstream/$branch" >/dev/null
        if [ $? -ne 0 ]; then
        	info 'there is diff -> merging'
			git merge "upstream/$branch"
			[ $? -ne 0 ] && error "sync failed: $repo" && exit -1
			git push origin
			[ $? -ne 0 ] && error "pushing origin failed: $repo" && exit -1
        fi
    fi
    cd ..
done
