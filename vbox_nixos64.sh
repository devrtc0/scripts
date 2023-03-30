#!/usr/bin/env sh

VBOX_BASEFOLDER=$HOME/vm
VBOX_VM_NAME=nixos
VBOX_NIC=wlp0s20f3
VBOX_ISO_IMG=$HOME/repo/nixos-iso/result/iso/nixos-22.05.20221129.0244e14-x86_64-linux.iso
VBOX_VM_FOLDER=$VBOX_BASEFOLDER/$VBOX_VM_NAME
VBOX_OS_TYPE=Linux_64

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
VBoxManage modifyvm $VBOX_VM_NAME --cpus 2 --memory 4096 --firmware=efi --vram 128 --tpm-type=none --nested-hw-virt=on --defaultfrontend gui
VBoxManage modifyvm $VBOX_VM_NAME --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm $VBOX_VM_NAME --nic1 bridged --nicpromisc1 allow-all --bridgeadapter1 $VBOX_NIC

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
