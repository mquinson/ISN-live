#! /bin/sh

# Create the initrd within the chroot

# Testing user ID 
uid=$(/usr/bin/id -u)
if [ $uid != "0" ] ; then
  echo "Please make sure to become root before running me" 2>&1 ; 
  exit 1
fi


set -ex

kver=`ls chroot/lib/modules/ |sort -r|head -n 1`
echo "XXX Generate the initrd (kver: $kver)"
rm -rf chroot/etc/ISN-live/initramfs
mkdir -p chroot/etc/ISN-live/initramfs
cp -r scripts/Mkinitramfs/initramfs-tools/* chroot/etc/ISN-live/initramfs
chroot chroot sh -c "mkinitramfs -d /etc/ISN-live/initramfs/ -o /boot/initrd.gz $kver"
cp chroot/boot/initrd.gz .
