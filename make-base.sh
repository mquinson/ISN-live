#! /bin/sh
NOM=clefISN
DEBIAN=wheezy
ARCH=i386
NOYAU="linux-image-486" # let the system pick the most recent one
USER=isn
# Testing user ID
uid=$(/usr/bin/id -u)
if [ $uid != "0" ] ; then
  echo "Please make sure to become root before running me" 2>&1 ;
  exit 1
fi


set -ex
# pour tester le script, mettre à false et placer le fi là où il faut
if true ; then
MIRROR="http://debian.mines.inpl-nancy.fr/debian/"

INCLUDEPKG="--include=xorg,xfce4,desktop-base,arandr"

echo "XXX download the elements"
if [ -e debootstrap-${ARCH}.cache.tgz ] ; then
  echo "archive already existing";
else
  debootstrap $INCLUDEPKG --arch $ARCH --make-tarball=debootstrap-${ARCH}.cache.tgz $DEBIAN $NOM $MIRROR
fi

echo "XXX building the chroot"
debootstrap $INCLUDEPKG --unpack-tarball=`pwd`/debootstrap-${ARCH}.cache.tgz --arch ${ARCH} $DEBIAN $NOM $MIRROR

echo "XXX add backports to the apt sources"

# on peut faire pour l'installation de wicd par exemple

mount none -t proc $NOM/proc
mount -o bind /dev $NOM/dev
mount -o bind /var/run $NOM/var/run/
chroot $NOM/ apt-get  install --yes wicd



# isnlive comme mot de passe root
sed -i -e '1,$s/root:\*:/root:FBa41ZgngtSCI:/' $NOM/etc/shadow

# on démonte /dev, /var/run, /dev
umount $NOM/proc
umount $NOM/dev
umount $NOM/var/run/
# initramfs
echo "XXX install a kernel"
cat > $NOM/etc/apt/sources.list <<EOF
deb http://ftp.fr.debian.org/debian/ experimental main contrib non-free

deb http://ftp.fr.debian.org/debian/ $DEBIAN main contrib non-free
deb-src http://ftp.fr.debian.org/debian/ $DEBIAN main contrib non-free

deb http://ftp.fr.debian.org/debian/ stable main contrib non-free

deb http://boisson.homeip.net/debian $DEBIAN divers
deb-src http://boisson.homeip.net/sources/ ./

deb http://security.debian.org/ $DEBIAN/updates main
deb-src http://security.debian.org/ $DEBIAN/updates main

deb http://backports.debian.org/debian-backports ${DEBIAN}-backports main'

EOF
chroot $NOM sh -c "apt-get update; apt-get  install  --yes  initramfs-tools"
zcat initramfs-isn.tgz | (cd $NOM ; tar x)
chroot $NOM sh -c "apt-get  install  --yes  $NOYAU"
chroot $NOM sh -c "apt-get  install  --yes mingetty"
# debut de l'aufs
fi


chroot $NOM sh -c "apt-get  install  --yes sudo rsync"
chroot $NOM sh -c "apt-get  install  --yes  locales"
cp /etc/locale.gen $NOM/etc
chroot $NOM locale-gen
cat <<EOF > $NOM/etc/default/locale
LANGUAGE="fr_FR:fr:en_GB:en"
LANG="fr_FR.UTF-8"
EOF
if [ ! -z "$(ls live-isn*deb)" ] ; then
    cp $(ls live-isn*deb) $NOM/tmp
    chroot $NOM sh -c "dpkg -i tmp/*.deb"
    rm $NOM/tmp/*.deb
chroot $NOM sh -c "apt-get clean"

# là mis en place du skel

# création de l'utilisateur
chroot $NOM sh -c "adduser --disabled-password --gecos \"Utilisateur ISN\" --quiet $USER"
fi    
sed -i -e '1,$s/^'$USER':x:/'$USER'::/' $NOM/etc/passwd
sed -i -e '1,$s/^'$USER':.:/'$USER'::/' $NOM/etc/shadow

sed -i -e '1,$s|^1:2345:respawn:/sbin/getty 38400 tty1|1:2345:respawn:/sbin/mingetty --noclear --autologin '$USER' tty1|' $NOM/etc/inittab




mksquashfs $NOM basesystem.sqh

