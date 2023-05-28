#!/usr/bin/env sh

pacman -Qi mpv >/dev/null 2>&1 || apps="$apps mpv"
pacman -Qi yt-dlp >/dev/null 2>&1 || apps="$apps yt-dlp"

if [ -n "$apps" ]; then
	sudo pacman --needed --noconfirm -S $apps
fi

mpv 'https://www.youtube.com/watch?v=1WAaIILN1HM' --no-video --no-resume-playback
