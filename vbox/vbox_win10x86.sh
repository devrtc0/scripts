#!/usr/bin/env sh

VBOX_VM_NAME=win10x86
VBOX_OS_TYPE=Windows10
VBOX_CORES=2
VBOX_MEMORY=4096
VBOX_NIC=wlp0s20f3
VBOX_ISO_IMG=$HOME/Downloads/win10_22.11.14.iso
VBOX_BASEFOLDER=$HOME/vm
VBOX_VM_FOLDER=$VBOX_BASEFOLDER/$VBOX_VM_NAME
VBOX_SEC_IF="$VBOX_SEC_IF" # INTNET or HOIF
VBOX_HOIF_PREFIX='192.168.56'
VBOX_FRONTEND=${VBOX_FRONTEND:-HEADLESS} # HEADLESS or GUI

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
VBoxManage storagectl $VBOX_VM_NAME --name SATA --add sata --controller IntelAhci --portcount 2 --hostiocache on

# create medium
[ -f "$VBOX_VM_FOLDER/disk001.vdi" ] && rm $VBOX_VM_FOLDER/disk001.vdi
VBoxManage createmedium disk --filename $VBOX_VM_FOLDER/disk001.vdi --size 50000

# mount mediums
VBoxManage storageattach $VBOX_VM_NAME --storagectl SATA --port 0 --type hdd --medium $VBOX_VM_FOLDER/disk001.vdi --nonrotational on --discard on
VBoxManage storageattach $VBOX_VM_NAME --storagectl SATA --port 1 --type dvddrive --medium $VBOX_ISO_IMG

# congigure the vm
VBoxManage modifyvm $VBOX_VM_NAME --cpus $VBOX_CORES --memory $VBOX_MEMORY --firmware=bios --vram 128 --tpm-type=none
VBoxManage modifyvm $VBOX_VM_NAME --clipboard-mode=bidirectional
if [ "$VBOX_FRONTEND" = "GUI" ]; then
	VBoxManage modifyvm "$VBOX_VM_NAME" --defaultfrontend gui --vrde off
elif [ "$VBOX_FRONTEND" = "HEADLESS" ]; then
	VBoxManage modifyvm "$VBOX_VM_NAME" --defaultfrontend headless --vrde on --vrdeproperty "TCP/Ports=55555"
fi
VBoxManage modifyvm $VBOX_VM_NAME --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm $VBOX_VM_NAME --nic1 bridged --nicpromisc1 allow-all --bridgeadapter1 $VBOX_NIC
if [ "INTNET" = "$VBOX_SEC_IF" ]; then
    VBoxManage modifyvm $VBOX_VM_NAME --nic2 intnet --nicpromisc2 allow-all
elif [ "HOIF" = "$VBOX_SEC_IF" ]; then
    VBOX_HOIF=$(vboxmanage list hostonlyifs | grep '^Name' | awk '{ print $2 }')
    if [ -z "$VBOX_HOIF" ]; then
        VBoxManage hostonlyif create
        VBOX_HOIF=$(vboxmanage list hostonlyifs | grep '^Name' | awk '{ print $2 }')
        VBoxManage hostonlyif ipconfig $VBOX_HOIF --ip "${VBOX_HOIF_PREFIX}.1"
    fi
    VBOX_DHCPSERVER=$(vboxmanage list dhcpservers | grep '^NetworkName')
    if [ -z "$VBOX_DHCPSERVER" ]; then
		VBoxManage dhcpserver add --ifname $VBOX_HOIF --ip "${VBOX_HOIF_PREFIX}.1" --netmask 255.255.255.0 --lowerip "${VBOX_HOIF_PREFIX}.101" --upperip "${VBOX_HOIF_PREFIX}.200"
		VBoxManage dhcpserver modify --ifname $VBOX_HOIF --enable
    fi
    VBoxManage modifyvm $VBOX_VM_NAME --nic2 hostonly --nicpromisc2 allow-all --hostonlyadapter2 $VBOX_HOIF
fi

VBoxManage usbfilter add 0 --target $VBOX_VM_NAME --name "SafeNet Token JC [0001]" --vendorid 0529 --productid 0620 --revision 0001 --manufacturer "SafeNet" --product "Token JC" --remote no

# start vm
# VBoxManage startvm $VBOX_VM_NAME

# shared folder
# mkdir -p $VBOX_VM_FOLDER/shared
# VBoxManage sharedfolder add $VBOX_VM_NAME --name shared --hostpath $VBOX_VM_FOLDER/shared/ --automount

# additions
# VBoxManage storageattach "$VBOX_VM_NAME" --storagectl SATA --port 1 --type dvddrive --medium additions

# remove medium
# VBoxManage storageattach "$VBOX_VM_NAME" --storagectl SATA --port 1 --medium none

# headless mode
# VBoxManage modifyvm $VBOX_VM_NAME --defaultfrontend headless --vrde on --vrdeproperty "TCP/Ports=55555"

# gui mode
# VBoxManage modifyvm $VBOX_VM_NAME --defaultfrontend gui --vrde off
