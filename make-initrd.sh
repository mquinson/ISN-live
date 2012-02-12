#! /bin/sh

# Create the initrd within the chroot

set -ex

kver=`ls chroot/lib/modules/ |sort -r|head -n 1`
echo "XXX Generate the initrd (kver: $kver)"
rm -rf chroot/etc/ISN-live/initramfs
mkdir -p chroot/etc/ISN-live/initramfs
cp -r scripts/Mkinitramfs/initramfs-tools/* chroot/etc/ISN-live/initramfs
chroot chroot sh -c "mkinitramfs -d /etc/ISN-live/initramfs/ -o /boot/initrd.gz $kver"
cp chroot/boot/initrd.gz .
