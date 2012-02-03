#!/bin/sh
date >> /tmp/dev_usb
echo $ACTION >> /tmp/dev_usb
echo $1 $ID_FS_TYPE $ID_TYPE >> /tmp/dev_usb
echo $ID_SERIAL >> /tmp/dev_usb
echo "----------">> /tmp/dev_usb

if [ "$ACTION" = "add" ] ; then
    NOM=$1_$ID_SERIAL
    DEVICE=/dev/$1
    if [ "$ID_FS_TYPE" = "" ] ; then
	ID_FS_TYPE=auto
    fi
    while [ -f /tmp/__insertusb ] ; do  /bin/true ; done
    touch  /tmp/__insertusb
    mkdir -p /media/$1
    echo "#$NOM" >> /etc/fstab
    if grep -q "$DEVICE " /etc/fstab > /dev/null ; then
	echo -n "#" >> /etc/fstab
    fi
    if [ $ID_FS_TYPE = ntfs ] ; then 
	ID_FS_TYPE=ntfs-3g
	chmod 777 /media/$1 
    fi
    echo $DEVICE /media/$1 $ID_FS_TYPE user,defaults 0 0 >> /etc/fstab
    rm /tmp/__insertusb
fi
if [ "$ACTION" = "remove" ] ; then
    NOM=$1_$ID_SERIAL
    DEVICE=/dev/$1
    while [ -f /tmp/fstab_mod ] ; do  /bin/true ; done
    touch /tmp/fstab_mod
    umount -f /media/$1
    rmdir /media/$1
#    echo "sed -e '/^#"$NOM"/{N;d}' /etc/fstab > /tmp/fstab_$1"> /tmp/edite.$1
#    cp /etc/fstab /tmp/fstab.$1
#    sh /tmp/edite.$1
    LISTE=`cat /etc/fstab | grep " /media" | awk '{print $2}' | sed -e 's|/media/||' | sort -u`
    cp /etc/fstab /tmp/fstab
    for device in $LISTE ; do
	if [ ! -d /media/$device ] ; then
	    grep -v $device' ' /tmp/fstab | grep -v $device'_' > /tmp/fstab_$device
	    cp /tmp/fstab_$device /tmp/fstab
	fi
    done
    if [ `ls -l /tmp/fstab | awk '{print $5}'` = "0" ] ; then
	touch /tmp/panique.$1
    else
	mv /tmp/fstab /etc/fstab
    fi
    rm /tmp/fstab_mod
fi
