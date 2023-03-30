SET vb_mng="%PROGRAMFILES%\Oracle\VirtualBox\VBoxManage.exe"
SET vb_name="arch64"
SET vb_vm="C:\Users\azat\vm"
SET vb_hdd="%vb_vm%\%vb_name%\disk001.vdi"
SET vb_install_iso="D:\AZAT\archlinux.iso"
SET vb_nic="Intel(R) Wi-Fi 6 AX200 160MHz"

"%vb_mng%" createvm --name "%vb_name%" --register --default --ostype ArchLinux --basefolder "%vb_vm%"

"%vb_mng%" storagectl "%vb_name%" --name SATA --remove
"%vb_mng%" storagectl "%vb_name%" --name SATA --add sata --controller IntelAhci --portcount 2 --hostiocache on

"%vb_mng%" createmedium disk --filename "%vb_hdd%" --size 50000

"%vb_mng%" storageattach "%vb_name%" --storagectl SATA --port 0 --type hdd --medium "%vb_hdd%" --nonrotational on --discard on
"%vb_mng%" storageattach "%vb_name%" --storagectl SATA --port 1 --type dvddrive --medium "%vb_install_iso%"

"%vb_mng%" modifyvm "%vb_name%" --memory 1024 --boot1 dvd --boot2 disk --boot3 none --boot4 none --defaultfrontend headless --vrde on --vrdeproperty "TCP/Ports=55556" --audio none --nic1 bridged --nicpromisc1 allow-all --bridgeadapter1 "%vb_nic%" --nic2 intnet --nicpromisc2 allow-all --tpm-type=none --firmware=efi

@REM start vm
@REM "%vb_mng%" startvm "%vb_name%"

@REM remove medium
@REM "%vb_mng%" storageattach "%vb_name%" --storagectl SATA --port 1 --medium none

EXIT /B 0
