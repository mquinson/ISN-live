#! /bin/sh
NAME=clefISN
DEBIAN=wheezy
ARCH=i386
KERNEL="linux-image-486" # let the system pick the most recent one
USER=isn
# Testing user ID
uid=$(/usr/bin/id -u)
if [ $uid != "0" ] ; then
  echo "Please make sure to become root before running me" 2>&1 ;
  exit 1
fi


set -ex
# To debug the script, it's handy to change to false, and put the fi to avoid what worked for you so far
if true ; then
MIRROR="http://debian.mines.inpl-nancy.fr/debian/"

INCLUDEPKG="--include=xorg,xfce4,desktop-base,arandr"

echo "XXX download the elements"
if [ -e debootstrap-${ARCH}.cache.tgz ] ; then
  echo "archive already existing";
else
  debootstrap $INCLUDEPKG --arch $ARCH --make-tarball=debootstrap-${ARCH}.cache.tgz $DEBIAN $NAME $MIRROR
fi

echo "XXX building the chroot"
debootstrap $INCLUDEPKG --unpack-tarball=`pwd`/debootstrap-${ARCH}.cache.tgz --arch ${ARCH} $DEBIAN $NAME $MIRROR

echo "XXX add backports to the apt sources"

# We could pick wicd for example

mount none -t proc $NAME/proc
mount -o bind /dev $NAME/dev
mount -o bind /var/run $NAME/var/run/
chroot $NAME/ apt-get  install --yes wicd



# root password is isnlive
sed -i -e '1,$s/root:\*:/root:FBa41ZgngtSCI:/' $NAME/etc/shadow

# let's forcefully unmount /dev, /var/run, /dev
# Sometimes, the umount fails, reporting that /dev or others is in use.
# But that's bully: there is another mount point to /dev (outside chroot), we can remove this one
umount -f $NAME/proc
umount -f $NAME/dev
umount -f $NAME/var/run/
# initramfs
echo "XXX install a kernel"
cat > $NAME/etc/apt/sources.list <<EOF
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
chroot $NAME sh -c "apt-get update; apt-get  install  --yes  initramfs-tools"
zcat initramfs-isn.tgz | (cd $NAME ; tar x)
chroot $NAME sh -c "apt-get  install  --yes  $KERNEL"
chroot $NAME sh -c "apt-get  install  --yes mingetty"
# debut de l'aufs
fi


chroot $NAME sh -c "apt-get  install  --yes sudo rsync"
chroot $NAME sh -c "apt-get  install  --yes  locales"
cp /etc/locale.gen $NAME/etc
chroot $NAME locale-gen
cat <<EOF > $NAME/etc/default/locale
LANGUAGE="fr_FR:fr:en_GB:en"
LANG="fr_FR.UTF-8"
EOF
if [ ! -z "$(ls live-isn*deb)" ] ; then
    cp $(ls live-isn*deb) $NAME/tmp
    chroot $NAME sh -c "dpkg -i tmp/*.deb"
    rm $NAME/tmp/*.deb
chroot $NAME sh -c "apt-get clean"

# Setup the system skeleton

# Create a user
chroot $NAME sh -c "adduser --disabled-password --gecos \"Utilisateur ISN\" --quiet $USER"
fi    
sed -i -e '1,$s/^'$USER':x:/'$USER'::/' $NAME/etc/passwd
sed -i -e '1,$s/^'$USER':.:/'$USER'::/' $NAME/etc/shadow

sed -i -e '1,$s|^1:2345:respawn:/sbin/getty 38400 tty1|1:2345:respawn:/sbin/mingetty --noclear --autologin '$USER' tty1|' $NAME/etc/inittab




mksquashfs $NAME basesystem.sqh

