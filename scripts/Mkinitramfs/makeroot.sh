#!/bin/sh

# hardcoded configurable options
# Default maximum size of dynamic ramdisk in kilobytes
RAMSIZE=1000000
# End of options
ISN_DIR=isnfs
ISN_NAME=base
LISTE_EXTENSIONS=extensions_isn

mount_agreg()
{
# echo appel de mount_agreg #D 
    echo "Fichier:" $1/$ISN_DIR/$ISN_NAME
    if test -n "$FOUND_ISN" ; then
	echo "$ISN_NAME trouve..."
#       mount #D
    fi
    if test -n "$FOUND_ISN" -a -f $1/$ISN_DIR/$ISN_NAME; then
    # DEBUG
	echo "6" > /proc/sys/kernel/printk
#	insmod $CLOOP_MODULE file=$1/$ISN_DIR/$ISN_NAME
#	mount /dev/cloop /ISN -o ro || FOUND_ISN=""
#	insmod $SQUASHFS
	mount $1/$ISN_DIR/$ISN_NAME /ISN -t squashfs -o loop || FOUND_ISN=""
 #    mount #D
 #    echo ">"$FOUND_ISN"<" #D
    fi
}


# echo On va appeler mount_agreg #D 
mount_agreg /cdrom
#echo ">"$FOUND_ISN"<" #D

# Est ce que tout va bien?
if test -n "$FOUND_ISN"
then
    
# Enable kernel messages
    echo "6" > /proc/sys/kernel/printk
    
# Set paths
    echo -n "Setting paths..."
    PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/X11R6/bin:."
    export PATH
    
# Debian weirdness
# echo copie alternatives #D 
    /ISN/bin/cp -a /ISN/etc/alternatives /etc/ 2>/dev/null
    
# on vide la table de hashage 
    hash -r
    
    
# nettoyage de /etc/mtab avec une entrée pour le cloop
    
    egrep " /ISN | /cdrom " /proc/mounts | sed 's|/dev/loop0 /cdrom \(.*\) 0 0|'$LOOP_SOURCE$ISO_PATH' /cdrom/ \1,loop=/dev/loop0 0 0|g' >> /etc/mtab
    
    
# la mémoire pour la taille du RAMDISK, vient de Knoopix
    FOUNDMEM="$(awk '/MemTotal/{print $2}' /proc/meminfo)"
    TOTALMEM="$(awk 'BEGIN{m=0};/MemFree|Cached/{m+=$2};END{print m}' /proc/meminfo)"
    
# Now we need to use a little intuition for finding a ramdisk size
# that keeps us from running out of space, but still doesn't crash the
# machine due to lack of Ram
    
# Minimum size of additional ram partitions
    MINSIZE=2000
# At least this much memory minus 30% should remain when home and var are full.
    MINLEFT=16000
# Maximum ramdisk size
    MAXSIZE="$(expr $TOTALMEM - $MINLEFT)"
# Default ramdisk size for ramdisk
    RAMSIZE="$(expr $TOTALMEM / 5)"
# echo TestRam $RAMSIZE #D 
# Check for sufficient memory to mount extra ramdisk for /home + /var
    if test -n "$TOTALMEM" -a "$TOTALMEM" -gt "$MINLEFT"; then
	test -z "$RAMSIZE" && RAMSIZE=1000000
	mkdir -p /ramdisk
# tmpfs/varsize version, can use swap
	RAMSIZE=$(expr $RAMSIZE \* 4)
	echo -n "Creating /ramdisk dynamic size=${RAMSIZE}k on shared memory..."
# We need /bin/mount here for the -o size= option
	echo Creation ramdisk $RAMSIZE
	
	mount -t tmpfs -o "size=${RAMSIZE}k" /ramdisk /ramdisk && mkdir -p /ramdisk/home /ramdisk/var && ln -s /ramdisk/home /ramdisk/var /
	echo "Done."
	mv /etc /ramdisk
	ln -s /ramdisk/etc /etc
    else
	mkdir -p /home /var
    fi
    echo -n "Fabrication du RAMDISK..."
# Create common WRITABLE (empty) dirs
    mkdir -p /var/run /var/backups /var/cache/apache /var/local /var/lock/news \
        /var/nis /var/preserve /var/state/misc /var/tmp /var/lib \
	/var/spool/cups/tmp /var/lib/samba \
        /mnt/cdrom /mnt/floppy  \
        /root /etc/sysconfig /etc/X11 /etc/cups /etc/dhcpc
    mkdir -p /ramdisk/mnt/cdrom /ramdisk/mnt/floppy /ramdisk/mnt/hd /ramdisk/mnt/test \
        /ramdisk/root /ramdisk/etc/sysconfig /ramdisk/etc/X11 /ramdisk/etc/cups /ramdisk/etc/dhcpc
    chmod 1777 /var/tmp
    chmod 1777 /var/lock
    
# le répertoire utilisateur avec ce qu'il faut dessus
    mkdir /home/live
# incomplet, on oublie une partie des modifications avec les extensions
    
# Create empty utmp and wtmp
    :> /var/run/utmp
    :> /var/run/wtmp
    
    if [ -f /etc/resolv.conf ] ; then
	rm /etc/resolv.conf
    fi
# on recopie la ligne de commande
    echo $CMDLINE > /etc/cmdlineboot
    touch /etc/resolv.conf
    
    rm -rf /etc/ftpusers /etc/passwd /etc/shadow /etc/group \
        /etc/ppp /etc/isdn /etc/ssh /etc/ioctl.save \
        /etc/inittab /etc/network /etc/sudoers \
        /etc/init /etc/localtime /etc/dhcpc /etc/pnm2ppa.conf 2>/dev/null
    
# on met le bon init
    mv /etc/init.sh /etc/init
    
# Extremely important, init crashes on shutdown if this is only a link
    :> /etc/ioctl.save
    :> /etc/pnm2ppa.conf
# Must exist for samba to work
    [ -d /var/lib/samba ] && :> /var/lib/samba/unexpected.tdb
    
# inutile avec unionfs
    
    df
    echo "...RAMDISK fini."
    
# Mis en place du modprobe au cas où
# bon le unionfs
    echo "/sbin/modprobe" > /proc/sys/kernel/modprobe
    
    
    echo "Initialisation du système"
    mkdir /ROOT
    cd /
    mount -t aufs aufs /ROOT -o dirs=/ramdisk=rw:/ISN=ro
    
# le pivot root ne marche pas ici scrogneugneu, usage de run-init
    
    mkdir /ROOT/oldroot
    cd /ROOT
    
# recherche d'une extension
#
# TODO: Prise en compte de la fin de l'extension pour hierarchiser
# le chargement des extensions. Bon, dans un premier temps pas urgent
# chargement donné soit par un fichier ordre_extensions, soit par
# date du plus vieux au plus récent.
#
    RAJOUT=""
    INDICE=1
    if [ -f /cdrom/ordre_extensions ] ; then
	LISTE_EXT=`cat /cdrom/ordre_extensions | sed -e 's|^|/cdrom/isnfs/|'`
    else
	LISTE_EXT=`ls -tr /cdrom/isnfs/extension*.sqh`
    fi
    for fichier in $LISTE_EXT ; do
#while [ -f /cdrom/isnfs/extension$NUMERO.sqh ] ; do
	if [ ! -b /dev/loop$INDICE ] ; then
	    cd /dev
	    mknod loop$INDICE b 7 $INDICE
	    cd /ROOT
	fi
	INDICE=`expr $INDICE + 1`
	DIR=`echo $fichier | sed -e 's/^.*\(extension.*\).sqh/\1/'`
	echo Installation de $DIR
	mkdir -p /$DIR
	mount $fichier /$DIR -t squashfs -o loop
	RAJOUT=:/$DIR=ro+wh$RAJOUT
    done
    
# recherche extension externe
    mkdir -p /extensions
    if /bin/trouvefichier UIS /extensions $LISTE_EXTENSIONS ; then
	for fichier in `cat /extensions/$LISTE_EXTENSIONS` ; do
#while [ -f /cdrom/isnfs/extension$NUMERO.sqh ] ; do
	    if [ ! -b /dev/loop$INDICE ] ; then
		cd /dev
		mknod loop$INDICE b 7 $INDICE
		cd /ROOT
	    fi
	    INDICE=`expr $INDICE + 1`
	    DIR=`echo $fichier | sed -e 's/^.*\(extension.*\).sqh/\1/'`
	    echo Installation de $DIR
	    mkdir -p /$DIR
	    mount /extensions/$ISN_DIR/$fichier /$DIR -t squashfs -o loop
	    RAJOUT=:/$DIR=ro+wh$RAJOUT
	done
    fi
    umount /dev/pts
    mv /dev /ramdisk
    echo Assemblage des repertoires
    mount -t aufs aufs /ROOT -o dirs=/ramdisk=rw$RAJOUT:/ISN=ro
    if [ ! -d /ROOT/oldroot ] ; then
	mkdir /ROOT/oldroot
    fi
    if [ ! -d /ROOT/proc ] ; then 
	mkdir /ROOT/proc
    fi
    if [ ! -d /ROOT/sys ] ; then
	mkdir /ROOT/sys
    fi
    echo Fabrication de /home/live

# mis à jour de /home/live
# (cd /ROOT/etc/skel ; tar c .) | (cd /ramdisk/home/live ; tar x)

    if [ -f /cdrom/home.tar.bfe ] ; then

# cas d'un cryptage

	PASSWD=`cat /proc/cmdline | grep clefcodage | sed -e 's/^.*clefcodage="\(.*\)".*$/\1/'`
	if [ ! -z $PASSWD ] ; then 
	    echo $PASSWD > /ramdisk/home/.clefcodage
	fi
	if [ -f /cdrom/clavier.kmap.gz ] ; then
	    loadkeys /cdrom/clavier.kmap.gz
	fi
	cd /ramdisk/home
	cp /cdrom/home.tar.bfe .
	bcrypt home.tar.bfe
	tar xf home.tar
	rm home.tar
	mkdir -p /ramdisk/home/live/public
	cd /cdrom/home
	cp -a . /ramdisk/home/live/public
	cd  /ramdisk/home/live/public
	if [ -f /cdrom/droitshome.txt ] ; then
	    cp /cdrom/droitshome.txt /tmp
	    chmod +x /tmp/droitshome.txt
	    /tmp/droitshome.txt
	    rm /tmp/droitshome.txt
	fi
	if [ -f /cdrom/liens.cpio ] ; then
	    cpio -i < /cdrom/liens.cpio
	fi
    else

# cas normal

	cd  /ramdisk/home/live
	if [ ! -f /cdrom/home/.perso ] ; then
	    cp -a /ROOT/etc/skel/. .
	fi
# (cd /cdrom/home ; tar c .) | (cd /ramdisk/home/live ; tar x)
	cd /cdrom/home
	cp -a . /ramdisk/home/live
	cd  /ramdisk/home/live
	if [ -f /cdrom/droitshome.txt ] ; then
	    cp /cdrom/droitshome.txt /tmp
	    chmod +x /tmp/droitshome.txt
	    /tmp/droitshome.txt
	    rm /tmp/droitshome.txt
	fi
	if [ -f /cdrom/liens.cpio ] ; then
	    cpio -i < /cdrom/liens.cpio
	fi
    fi
    cd /
#chroot /ROOT chmod -R +w /home/live
#chroot /ROOT chown -R live /home/live/
    chmod -R +w /ramdisk/home/live
    chown -R 1000.1000 /ramdisk/home/live/
# on conserve des liens vers les systèmes de fichiers séparés
    chroot /ROOT mount /proc
    chroot /ROOT mount /sys
    mkdir -p /ROOT/oldroot/ramdisk
    mount -o bind /ramdisk /ROOT/oldroot/ramdisk
    mkdir -p /ROOT/oldroot/cdrom
    mount -o bind /cdrom /ROOT/oldroot/cdrom
    for dir in `ls -d /extension*` ; do
	if [ -d /$dir ] ; then
	    mkdir -p /ROOT/oldroot/$dir
	    mount -o bind /$dir /ROOT/oldroot/$dir
	fi
    done
    umount /proc/bus/usb
    umount /proc
    umount /sys
    echo RAMDISK fini, boot normal.
    echo Running init
    cd /
    exec /bin/run-init /ROOT /sbin/init $* < /ROOT/dev/console > /ROOT/dev/console 2>&1
    
    
    
else
    echo "Je n'arrive pas à trouver un système de fichier."
    echo "Voilà un shell limité."
    PS1="live# "
    export PS1
    echo "6" > /proc/sys/kernel/printk
# Allow signals
    trap 1 2 3 15
    exec /bin/sh
fi
