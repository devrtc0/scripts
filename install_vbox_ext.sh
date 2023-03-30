#!/usr/bin/env sh

VBOX_VERSION=$(vboxmanage -V | awk -Fr '{ print $1 }')
[ $? -ne 0 ] && echo "Couldn't take Virtualbox version" && exit -1

VBOX_EXT=$(vboxmanage list extpacks | grep '^Version' | awk '{ print $2 }')
[ $? -ne 0 ] && echo "Couldn't take Extension version" && exit -1

if [ "$VBOX_VERSION" = "$VBOX_EXT" ]; then
	echo "Same versions: $VBOX_EXT"
	exit
fi

echo "Virtualbox version: $VBOX_VERSION"
if [ -z "$VBOX_EXT" ]; then
	echo "Extension is not installed"
else
	echo "Extension version: $VBOX_EXT"
	sudo vboxmanage extpack uninstall "Oracle VM VirtualBox Extension Pack"
	[ $? -ne 0 ] && echo "Couldn't uninstall old Extension" && exit -1
fi

EXT_FILE="/tmp/Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack"
curl -L -o $EXT_FILE "https://download.virtualbox.org/virtualbox/${VBOX_VERSION}/Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack"
[ $? -ne 0 ] && echo "Couldn't download new Extension" && exit -1

LICENSE=$(tar -xzf $EXT_FILE --wildcards '*ExtPack-license.txt' -O | sha256sum | awk '{ print $1 }')
[ $? -ne 0 ] && echo "Couldn't take Extension license hash" && exit -1

sudo vboxmanage extpack install --accept-license="$LICENSE" $EXT_FILE
[ $? -ne 0 ] && echo "Couldn't install new Extension" && exit -1
