#! /bin/sh



set -ex

MIRROR="http://debian.mines.inpl-nancy.fr/debian/"

INCLUDEPKG="--include=xorg,lxde,gdm,network-manager-gnome,desktop-base"

echo "XXX download the elements"
if [ -e debootstrap.cache.tgz ] ; then 
  echo "archive already existing";
else
  debootstrap $INCLUDEPKG --make-tarball=debootstrap.cache.tgz stable chroot $MIRROR
fi

echo "XXX building the chroot"
debootstrap $INCLUDEPKG --unpack-tarball=`pwd`/debootstrap.cache.tgz stable chroot $MIRROR

echo "XXX add backports to the apt sources"
sh -c "echo 'deb http://backports.debian.org/debian-backports squeeze-backports main' >> chroot/etc/apt/sources.list"

echo "XXX install a kernel"
chroot chroot sh -c "apt-get update; apt-get -t squeeze-backports install --yes linux-image-amd64"
kver=`ls chroot/lib/modules/ |sort -r|head -n 1`

echo "XXX Generate the initrd"
mkdir -p chroot/etc/ISN-live/initramfs
cp -r scripts/Mkinitramfs/initramfs-tools/* chroot/etc/ISN-live/initramfs
chroot chroot sh -c "mkinitramfs -d /etc/ISN-live/initramfs/ -o /boot/initrd.gz $kver"
cp chroot/tmp/initrd.gz .

echo "XXX Compressing the squash filesystem"
mksquashfs chroot basesystem.sqh

