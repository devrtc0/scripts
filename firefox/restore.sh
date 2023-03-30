#!/usr/bin/env sh

PROFILE=$HOME/.mozilla/firefox

[ $(find $PROFILE/*/prefs.js | wc -l) -ne 1 ] && echo 'The number of profile folders is not equal to 1' && exit -1
ubo=$(rg -r '"$1"' -o -N -e '^user_pref\("extensions.webextensions.uuids", "(.*)"\);' $PROFILE/*/prefs.js | jq -r 'fromjson | ."uBlock0@raymondhill.net"')
um=$(rg -r '"$1"' -o -N -e '^user_pref\("extensions.webextensions.uuids", "(.*)"\);' $PROFILE/*/prefs.js | jq -r 'fromjson | ."uMatrix@raymondhill.net"')
kpsxc=$(rg -r '"$1"' -o -N -e '^user_pref\("extensions.webextensions.uuids", "(.*)"\);' $PROFILE/*/prefs.js | jq -r 'fromjson | ."keepassxc-browser@keepassxc.org"')
yteh=$(rg -r '"$1"' -o -N -e '^user_pref\("extensions.webextensions.uuids", "(.*)"\);' $PROFILE/*/prefs.js | jq -r 'fromjson | ."enhancerforyoutube@maximerf.addons.mozilla.org"')


type xclip >/dev/null 2>&1 && echo "$HOME/repo/settings/my-ublock-backup.txt" | xclip -selection clipboard
firefox "moz-extension://$ubo/dashboard.html#settings.html"

type xclip >/dev/null 2>&1 && echo "$HOME/repo/settings/my-umatrix-backup.txt" | xclip -selection clipboard
firefox "moz-extension://$um/dashboard.html#about"

type xclip >/dev/null 2>&1 && echo "$HOME/repo/settings/keepassxc_settings.json" | xclip -selection clipboard
firefox "moz-extension://$kpsxc/options/options.html"

type xclip >/dev/null 2>&1 && cat "$HOME/repo/settings/youtube-enhancer.json" | xclip -selection clipboard
firefox "moz-extension://$yteh/options.html"

type xclip >/dev/null 2>&1 && echo "$HOME/repo/settings/bookmarks.html" | xclip -selection clipboard
firefox
