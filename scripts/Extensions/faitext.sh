#!/bin/sh
usage()
{
cat << EOF
Utilisation: faiext.sh arguments
 -b base: utilise le fichier base comme base de système de fichiers
 -B base: edition de la base, n'utilise pas -n, -e, -b
 -n nom: nom de l'extension concernée ou du répertoire (nom.dir) correspondant
 -d : crée une extension séparée dpkg contenant la base dpkg de l'extension.
 -e extension: chargement de l'extension extension 
 -f : finalise l'extension en fabriquant le fichier .sqh à la fin
 -h : usage de la commande
EOF
}
unset EDIT
unset DODPKG
LSTEXT=""
FINALISE=""
while getopts “hdb:fB:n:e:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         b)
             BASEFILE=$OPTARG
             ;;
	 d)
	     DODPKG=1
	     ;;
         n)
             NOM=$OPTARG
             ;;
         B)
             EDIT=1
	     BASEFILE=$OPTARG
	     ;;
         e)
             LSTEXT="$LSTEXT "$OPTARG
             ;;
	 f)
	     FINALISE=1
	     ;;
         ?)
             usage
             exit 1
             ;;
     esac
done

if [ -z $EDIT ] ; then
MONTAGE=/var/$(tempfile)
BASE=/var/$(tempfile)
DPKG=/var/$(tempfile)
SUPPORT=/var/$(tempfile)
echo $MONTAGE $BASE $DPKG $SUPPORT | sed -e 's|/var||g' | xargs rm
MONTESQH="mount -o loop -t squashfs "
    if [ -z $NOM ] ; then
	if [ -z $BASEFILE ] ; then
	    usage
	    exit 1
	else
	    mkdir -p $DPKG
	    mkdir -p $BASE
	    mkdir -p $MONTAGE
	    TEMP=$(tempfile)
	    rm $TEMP
	    mkdir -p $TEMP
	    $MONTESQH $BASEFILE $BASE
	    $MONTESQH extension_dpkg-$(cat $BASE/FB).sqh $DPKG
	    CHAINE=":$DPKG=ro:$BASE=ro"
	    mkdir -p $SUPPORT
	    for ext in $LSTEXT ; do
		EXT=$(basename $ext | sed -e 's/.sqh//')
		mkdir -p $SUPPORT/$EXT
		$MONTESQH $ext $SUPPORT/$EXT
		CHAINE=":$SUPPORT/$EXT=ro$CHAINE"
	    done    
	    mount -t aufs aufs $MONTAGE -o dirs=$TEMP=rw$CHAINE 
	    mount -t proc proc $MONTAGE/proc
	    mount -o bind /dev $MONTAGE/dev
	    chroot $MONTAGE
	    umount $MONTAGE/dev
	    umount $MONTAGE/proc
	    umount $MONTAGE
	    for f in $(ls $SUPPORT) ; do
		umount $SUPPORT/$f
	    done
	    umount $BASE
	    umount $DPKG
	    rm -Rf $TEMP
	    rmdir $BASE $MONTAGE $DPKG
	    rm -Rf $SUPPORT
	    exit 0
	fi
    fi
    mkdir -p $DPKG
    mkdir -p $SUPPORT
    mkdir -p $BASE
    mkdir -p $MONTAGE
    NOM=$(echo $NOM | sed -e 's/.dir//' | sed -e 's|/$||')
    if [ ! -d $NOM.dir ] ; then
	if [ -f extension_$NOM.sqh ] ; then
	    unsquashfs extension_$NOM.sqh
	    mv squashfs-root $NOM.dir
	    if [ -f extension_dpkg_$NOM.sqh ] ; then
		unsquashfs extension_dpkg_$NOM.sqh
		(cd squashfs-root ; tar c .) | (cd $NOM.dir ; tar x)
		rm -R squashfs-root
	    fi
	fi
	mkdir -p $NOM.dir
    fi
    $MONTESQH $BASEFILE $BASE
    $MONTESQH extension_dpkg-$(cat $BASE/FB).sqh $DPKG
    CHAINE=":$DPKG=ro:$BASE=ro"
    for ext in $LSTEXT ; do
	EXT=$(basename $ext | sed -e 's/.sqh//')
	mkdir -p $SUPPORT/$EXT
	$MONTESQH $ext $SUPPORT/$EXT
	CHAINE=":$SUPPORT/$EXT=ro:$CHAINE"
    done    
    mount -t aufs aufs $MONTAGE -o dirs=$NOM.dir=rw$CHAINE 
    mount -t proc proc $MONTAGE/proc
    mount -o bind /dev $MONTAGE/dev
    chroot $MONTAGE
    umount $MONTAGE/dev
    umount $MONTAGE/proc
    umount $MONTAGE
    ls $SUPPORT
    for f in $(ls $SUPPORT) ; do
	echo $f
	umount $SUPPORT/$f
    done
    [ -d $SUPPORT/* ] && rmdir $SUPPORT/*
    umount $DPKG
    umount $BASE
    rmdir $BASE $MONTAGE $DPKG
    [ -d $SUPPORT ] && rmdir $SUPPORT
    if [ ! -z $FINALISE ] ; then
	echo Finalisation de $NOM
	[ ! -z "$(ls $NOM.dir/var/cache/apt/archives/*.deb)" ] && rm  $NOM.dir/var/cache/apt/archives/*.deb
	if [ ! -z $DODPKG ] ; then
	    mksquashfs $NOM.dir extension_$NOM.sqh -wildcards -noappend -e var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian*
	    if [ ! -z $LSTEXT ] ; then
		doextension.sh extension_$NOM.sqh $LSTEXT
	    fi
	    ARCHIVE=$(tempfile)
	    rm $ARCHIVE
	    mkdir -p $ARCHIVE
	    (cd $NOM.dir ; tar c var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian* ) | (cd $ARCHIVE ; tar x)
	    mksquashfs $ARCHIVE extension_dpkg_$NOM.sqh  -noappend
	    doextension.sh extension_dpkg_$NOM.sqh extension_$NOM.sqh 
	    rm -Rf $ARCHIVE
	else
	    mksquashfs $NOM.dir extension_$NOM.sqh -noappend
	fi
    fi    
else
# edition de la base
    if [ -z $BASEFILE ] ; then
	usage
	exit 1
    fi
    if [ ! -d $BASEFILE.dir ] ; then
	unsquashfs $BASEFILE
	mv squashfs-root $BASEFILE.dir
	NOMDPKGBASE=extension_dpkg-$(cat $BASEFILE.dir/FB).sqh
	unsquashfs extension_dpkg-$(cat $BASEFILE.dir/FB).sqh
	(cd squashfs-root ; tar c .) | (cd $BASEFILE.dir ; tar x)
	rm    -R squashfs-root
    fi
    mount -t proc proc $BASEFILE.dir/proc
    mount -o bind /dev $BASEFILE.dir/dev
    chroot $BASEFILE.dir
    umount $BASEFILE.dir/proc
    umount $BASEFILE.dir/dev
    if [ ! -z $FINALISE ] ; then
	echo Finalisation de la base
	mv $BASEFILE $BASEFILE.old
	mv $NOMDPKGBASE $NOMDPKGBASE.old
	[ ! -z "$(ls $BASEFILE.dir/var/cache/apt/archives/*.deb)" ] && rm  $BASEFILE.dir/var/cache/apt/archives/*.deb
	mksquashfs $BASEFILE.dir $BASEFILE -wildcards -noappend -e var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian*
	ARCHIVE=$(tempfile)
	rm $ARCHIVE
	mkdir -p $ARCHIVE
	(cd $BASEFILE.dir ; tar c var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian* ) | (cd $ARCHIVE ; tar x)
	mksquashfs $ARCHIVE extension_dpkg-$(cat $BASEFILE.dir/FB).sqh  -noappend
	rm -Rf $ARCHIVE $BASEFILE.dir
    fi
fi