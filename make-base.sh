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

echo "XXX Compressing the squash filesystem"
sudo mksquashfs chroot basesystem.sqh
