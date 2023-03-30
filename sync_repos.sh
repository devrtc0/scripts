#!/usr/bin/env sh

if [ $# -eq 0 ]; then
    echo "dir is requried"
    echo "usage: ./sync_repos.sh <dir>"
    exit -1
fi

if [ -z "$TOKEN" ]; then
    echo "env TOKEN required"
    exit -1
fi

if [ -z "$USER" ]; then
    echo "env USER required"
    exit -1
fi

API_VERSION="2022-11-28"

pacman -Qi jq >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "jq is required"
    exit -1
fi
pacman -Qi git >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "git is required"
    exit -1
fi
pacman -Qi coreutils >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "coreutils is required"
    exit -1
fi

WORKDIR=$(readlink -f $1)
if [ $? -ne 0 ]; then
    echo "wrong dir name $1"
    exit -1
fi
if [ ! -d "$WORKDIR" ]; then
    echo "$1 not exists"
    exit -1
fi

repos_info=$(curl -SsL \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-GitHub-Api-Version: $API_VERSION" https://api.github.com/users/$USER/repos)
[ $? -ne 0 ] && echo "repos getting" && exit -1
repos=$(echo "$repos_info" | jq -r '.[] | .ssh_url')
[ $? -ne 0 ] && echo "repos parsing" && exit -1

cd $WORKDIR
for repo in $repos
do
    name=$(basename -s '.git' "$repo")
    repo_info=$(curl -SsL \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer $TOKEN" \
            -H "X-GitHub-Api-Version: $API_VERSION" https://api.github.com/repos/$USER/$name)
    [ $? -ne 0 ] && echo "repo $repo getting" && exit -1
    if [ ! -d "$WORKDIR/$name" ]; then
        git clone "$repo"
        [ $? -ne 0 ] && echo "$repo cloning" && exit -1
        upstream=$(echo "$repo_info" | jq -r '.source.ssh_url')
        [ $? -ne 0 ] && echo "upstream parsing for $repo" && exit -1
        if [ "null" = "$upstream" ]; then
            echo "no upstream for $repo"
        else
            cd "$name"
            echo "setting upstream $upstream for $repo"
            git remote add upstream "$upstream"
            cd ..
        fi
    fi
    fork=$(echo "$repo_info" | jq '.fork')
    [ $? -ne 0 ] && echo "fork parsing for $repo" && exit -1
    cd "$name"
    git pull
    [ $? -ne 0 ] && echo "pull failed: $repo" && exit -1
    if [ "true" = "$fork" ]; then
        git fetch upstream
        [ $? -ne 0 ] && echo "fetch failed: $repo" && exit -1
    fi
    cd ..
done
