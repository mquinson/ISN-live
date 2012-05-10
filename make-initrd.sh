#! /bin/sh
NAME=clefISN

# Create the initrd within the chroot

# Testing user ID 
uid=$(/usr/bin/id -u)
if [ $uid != "0" ] ; then
  echo "Please make sure to become root before running me" 2>&1 ; 
  exit 1
fi


set -ex

kver=`ls $NAME/lib/modules/ |sort -r|head -n 1`
echo "XXX Generate the initrd (kver: $kver)"
rm -rf $NAME/etc/ISN-live/initramfs
mkdir -p $NAME/etc/ISN-live/initramfs
cp -r scripts/Mkinitramfs/initramfs-tools/* $NAME/etc/ISN-live/initramfs
chroot $NAME sh -c "mkinitramfs -d /etc/ISN-live/initramfs/ -o /boot/initrd.gz $kver"
cp $NAME/boot/initrd.gz .
