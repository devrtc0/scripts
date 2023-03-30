#!/usr/bin/env sh

VBOX_VM_NAME="${VBOX_VM_NAME:-arch}"
VBOX_OS_TYPE=ArchLinux_64
VBOX_CORES="${VBOX_CORES:-4}"
VBOX_MEMORY="${VBOX_MEMORY:-4096}"
VBOX_NIC=wlp0s20f3
VBOX_ISO_IMG=$HOME/repo/archiso/out/archlinux.iso
VBOX_BASEFOLDER=$HOME/vm
VBOX_VM_FOLDER=$VBOX_BASEFOLDER/$VBOX_VM_NAME
VBOX_INTNET=''
VBOX_FRONTEND="${VBOX_FRONTEND:-HEADLESS}" # HEADLESS or GUI

echo "Create VM with the following settings"
echo "VBOX_VM_NAME = $VBOX_VM_NAME"
echo "VBOX_CORES = $VBOX_CORES"
echo "VBOX_MEMORY = ${VBOX_MEMORY} Mb"
echo "VBOX_FRONTEND = $VBOX_FRONTEND"
select yn in "Yes" "No"; do
	case $yn in
		Yes ) break;;
		No ) exit;;
	esac
done

# CHECKS
VBoxManage showvminfo "$VBOX_VM_NAME" >/dev/null 2>&1 && echo "$VBOX_VM_NAME already exists" && exit -1

if [ ! -e "$VBOX_ISO_IMG" ]; then
    echo "ISO file $VBOX_ISO_IMG doesn't exist"
    exit -1
fi

mkdir -p $VBOX_BASEFOLDER
rm -rf $VBOX_VM_FOLDER

# CREATION
# create vm
VBoxManage createvm --name $VBOX_VM_NAME --register --default --ostype $VBOX_OS_TYPE --basefolder $VBOX_BASEFOLDER

# storage configuration
VBoxManage storagectl $VBOX_VM_NAME --name SATA --remove
VBoxManage storagectl $VBOX_VM_NAME --name SATA --add pcie --controller NVMe --portcount 1 --hostiocache on
VBoxManage storagectl $VBOX_VM_NAME --name IDE --remove
VBoxManage storagectl $VBOX_VM_NAME --name IDE --add ide --controller PIIX4 --portcount 2 --hostiocache on

# create medium
[ -f "$VBOX_VM_FOLDER/disk001.vdi" ] && rm $VBOX_VM_FOLDER/disk001.vdi
VBoxManage createmedium disk --filename $VBOX_VM_FOLDER/disk001.vdi --size 50000

# mount mediums
VBoxManage storageattach $VBOX_VM_NAME --storagectl SATA --port 0 --type hdd --medium $VBOX_VM_FOLDER/disk001.vdi --nonrotational on --discard on
VBoxManage storageattach $VBOX_VM_NAME --storagectl IDE --device 0 --port 0 --type dvddrive --medium $VBOX_ISO_IMG

# congigure the vm
VBoxManage modifyvm $VBOX_VM_NAME --cpus $VBOX_CORES --memory $VBOX_MEMORY --firmware=efi --vram 128 --tpm-type=none
VBoxManage modifyvm $VBOX_VM_NAME --clipboard-mode=bidirectional
if [ "$VBOX_FRONTEND" = "GUI" ]; then
	VBoxManage modifyvm "$VBOX_VM_NAME" --defaultfrontend gui --vrde off
elif [ "$VBOX_FRONTEND" = "HEADLESS" ]; then
	VBoxManage modifyvm "$VBOX_VM_NAME" --defaultfrontend headless --vrde on --vrdeproperty "TCP/Ports=55555"
fi
VBoxManage modifyvm $VBOX_VM_NAME --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm $VBOX_VM_NAME --nic1 bridged --nicpromisc1 allow-all --bridgeadapter1 $VBOX_NIC
if [ ! -z "$VBOX_INTNET" ]; then
    VBoxManage modifyvm $VBOX_VM_NAME --nic2 intnet --nicpromisc2 allow-all
fi

# start vm
# VBoxManage startvm $VBOX_VM_NAME

# shared folder
# mkdir -p $VBOX_BASEFOLDER/$VBOX_VM_NAME/shared
# VBoxManage sharedfolder add $VBOX_VM_NAME --name shared --hostpath $VBOX_BASEFOLDER/$VBOX_VM_NAME/shared/ --automount

# remove medium
# VBoxManage storageattach "$VBOX_VM_NAME" --storagectl IDE --device 0 --port 0 --medium none

# headless mode
# VBoxManage modifyvm $VBOX_VM_NAME --defaultfrontend headless --vrde on --vrdeproperty "TCP/Ports=55555"

# gui mode
# VBoxManage modifyvm $VBOX_VM_NAME --defaultfrontend gui --vrde off
