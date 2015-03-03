#!/bin/sh
if [ -z "$SUDO_COMMAND" ] ; then
    sudo faitext.sh $*
else
#export
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
 -F : Fusionne les extensions avec la base
 -D : detruit le répertoire après finalisation de la base
 -m : Edition de l'extension en RAM
 -h : usage de la commande
EOF
}

# 12 chiffres + un ^J
# analyse une suite d'extensions et sort l'ordre de chargement
#
INDICELOOP=$(mount | grep -c loop)
MAX_LONGUEUR=13

makeloop ()
{
    if [ ! -b /dev/loop$INDICELOOP ] ; then
	mknod /dev/loop$INDICELOOP b 7 $INDICELOOP
    else
	/bin/true
#	echo /dev/loop$INDICELOOP existant
    fi
    INDICELOOP=$(expr $INDICELOOP + 1)
}

analyse_extension ()
{
eval NOM_$2=$1
#eval echo NOM_$2 = \$NOM_$2
if $(tail -c $MAX_LONGUEUR $1 | grep -q -E "^[0-9 ]+$") ; then
    eval NOMB=\$NOM_$2
#    echo NOMB = $NOMB
    LONGUEUR=$(tail -c $MAX_LONGUEUR $NOMB)
    LONGUEUR=$(expr $LONGUEUR + 0)
    LONGUEUR_REELLE=$(ls -l ${NOMB} | awk '{print $5}')
    LST=$(tail -c $(expr $LONGUEUR_REELLE - $LONGUEUR) ${NOMB})
        for f in $LST ; do
	    if $(echo $f | grep -q extension_) ; then
		NEXT=$(expr $2 + 1)
#		echo Next=$NEXT
		eval unset TAB_$NEXT
		analyse_extension $f $NEXT
		eval TAB_$2=\"\$TAB_$2 \$TAB_$NEXT\"
#		eval echo TAB_$2 donne \$TAB_$2
	    fi
	done
fi
eval TAB_$2=\"\$TAB_$2 \$NOM_$2\"
#eval echo TAB_$2 = \$TAB_$2
}

analyse_liste ()
{
LISTE=""
while [ ! -z $1 ] ; do
    analyse_extension $1 0
    eval RES=\$TAB_0
    for i in $RES ; do
	if $(echo $LISTE | grep -v -q $i) ; then
	    LISTE=$LISTE" "$i
	fi
    done
    shift
done
echo $LISTE
}

complete ()
{
    TEST=1$1
    if [ $TEST -lt 1000000000000 ] ; then
	complete "0$1"
    else
	RESULTAT=$1
    fi
}

unset EDIT
unset DODPKG
unset OPTIMISE
LSTEXTORG=""
FINALISE=""
while getopts “mhodb:fFB:n:e:” OPTION
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
	 o)
	     OPTIMISE=1
	     ;;
         n)
             NOM=$OPTARG
             ;;
         B)
             EDIT=1
	     BASEFILE=$OPTARG
	     ;;
         e)
             LSTEXTORG="$LSTEXTORG "$OPTARG
             ;;
	 f)
	     FINALISE=1
	     ;;
	 F)
	     BIGFUSION=1
	     ;;
	 D)
	     DESTROY=1
	     ;;
	 m)
	     RAMFS=1
	     FINALISE=1
	     ;;
         ?)
             usage
             exit 1
             ;;
     esac
done

LSTEXT=
if [ ! -z "$LSTEXTORG" ] ; then
    for PAQ in $(analyse_liste $LSTEXTORG) ; do
	if [ -z "$(echo $LSTEXT | grep $PAQ)" ] ; then
	    LSTEXT="$LSTEXT $PAQ"
	fi
    done
fi


echo $EDIT
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
	    makeloop
	    $MONTESQH $BASEFILE $BASE
	    makeloop
	    $MONTESQH extension_dpkg-$(cat $BASE/FB).sqh $DPKG
	    CHAINE=":$DPKG=ro:$BASE=ro"
	    mkdir -p $SUPPORT
	    for ext in $LSTEXT ; do
		if [ -f $ext ] ; then
		    EXT=$(basename $ext | sed -e 's/.sqh//')
		    mkdir -p $SUPPORT/$EXT
		    makeloop
		    $MONTESQH $ext $SUPPORT/$EXT
		    CHAINE=":$SUPPORT/$EXT=ro$CHAINE"
		else
		    echo $ext absent, on continue quand même...
		fi
	    done    
#	    echo "mount -t aufs aufs $MONTAGE -o dirs=$TEMP=rw$CHAINE "
	    makeloop
	    mount -t aufs aufs $MONTAGE -o dirs=$TEMP=rw$CHAINE 
	    mount -t proc proc $MONTAGE/proc
	    mount -o bind /dev $MONTAGE/dev
	    ln -s $MONTAGE /var/tmp/ISN
	    cp /etc/resolv.conf /var/tmp/ISN/etc
	    chroot $MONTAGE
	    rm /var/tmp/ISN
	    umount $MONTAGE/dev
	    umount $MONTAGE/proc
	    umount $MONTAGE
	    for f in $(ls $SUPPORT) ; do
		sleep 0.1
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
    if [ ! -d $NOM.dir ] || [ ! -z $RAMFS ] ; then
	if [ ! -z $RAMFS ] ;then
	    mkdir -p $NOM.dir
	    mount -t tmpfs tmpfs $NOM.dir
	    if [ -f extension_$NOM.sqh ] ; then
		cd $NOM.dir
		unsquashfs ../extension_$NOM.sqh
		cd squashfs-root
		mv * ..
		mv .??* ..
		cd ..
		rm -Rf squashfs-root
		if [ -f ../extension_dpkg_$NOM.sqh ] ; then
		    unsquashfs extension_dpkg_$NOM.sqh
		    (cd squashfs-root ; tar c .) | (cd .. ; tar x)
		    rm -R squashfs-root
		fi
		cd ..
	    fi
	else
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
    fi
    makeloop
    $MONTESQH $BASEFILE $BASE
    makeloop
    $MONTESQH extension_dpkg-$(cat $BASE/FB).sqh $DPKG
    CHAINE=":$DPKG=ro:$BASE=ro"
    for ext in $LSTEXT ; do
	if [ -f $ext ] ; then
	    EXT=$(basename $ext | sed -e 's/.sqh//')
	    mkdir -p $SUPPORT/$EXT
	    makeloop
	    $MONTESQH $ext $SUPPORT/$EXT
	    CHAINE=":$SUPPORT/$EXT=ro$CHAINE"
	else
	    echo $ext absent, on continue quand même...
	fi
    done    
#    echo "mount -t aufs aufs $MONTAGE -o dirs=$NOM.dir=rw$CHAINE "
    makeloop
    mount -t aufs aufs $MONTAGE -o dirs=$NOM.dir=rw$CHAINE 
    mount -t proc proc $MONTAGE/proc
    mount -o bind /dev $MONTAGE/dev
    ln -s $MONTAGE /var/tmp/ISN
    cp /etc/resolv.conf /var/tmp/ISN/etc
    chroot $MONTAGE
    rm /var/tmp/ISN
    umount $MONTAGE/dev
    umount $MONTAGE/proc
    if [ ! -z $BIGFUSION ] ; then
	echo Fusion sur $BASE
	[ ! -z "$(ls $MONTAGE/var/cache/apt/archives/*.deb)" ] && rm  $NOM.dir/var/cache/apt/archives/*.deb
	NOMDPKGBASE=extension_dpkg-$(cat $BASEFILE.dir/FB).sqh
	mv $BASEFILE $BASEFILE.old
	mv $NOMDPKGBASE $NOMDPKGBASE.old
	mksquashfs $MONTAGE $BASEFILE -wildcards -noappend -e var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian*
	if [ ! -z "$SUDO_USER" ] ; then
	    chown $SUDO_USER $BASEFILE
	fi
	ARCHIVE=$(tempfile)
	rm $ARCHIVE
	mkdir -p $ARCHIVE
	(cd $MONTAGE ; tar c var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian* ) | (cd $ARCHIVE ; tar x)
	mksquashfs $ARCHIVE extension_dpkg-$(cat $MONTAGE/FB).sqh  -noappend
	if [ ! -z "$SUDO_USER" ] ; then
	    chown $SUDO_USER extension_dpkg-$(cat $MONTAGE/FB).sqh
	fi
	rm -Rf $ARCHIVE
    fi
    umount $MONTAGE
    ls $SUPPORT
    for f in $(ls $SUPPORT) ; do
	echo $f
	umount $SUPPORT/$f
    done
    for i in $(ls $SUPPORT) ; do rmdir $SUPPORT/$i ;done
#    [ -d $SUPPORT/* ] && rmdir $SUPPORT/*
    umount $DPKG
    umount $BASE
    rmdir $BASE $MONTAGE $DPKG
    [ -d $SUPPORT ] && rmdir $SUPPORT
    [ ! -z $BIGFUSION ] && exit 0
    if [ ! -z $FINALISE ] ; then
	echo Finalisation de $NOM
	[ ! -z "$(ls $NOM.dir/var/cache/apt/archives/*.deb)" ] && rm  $NOM.dir/var/cache/apt/archives/*.deb
	[ ! -z "$OPTIMISE" ] && rm $NOM.dir/var/cache/apt/*.bin $NOM.dir/var/lib/apt/lists/*
	if [ ! -z $DODPKG ] ; then
	    mksquashfs $NOM.dir extension_$NOM.sqh -wildcards -noappend -e var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian*
	    LSTEXTP=
	    for i in $LSTEXT ; do
		if [ ! -z "$(echo $i | grep -v extension_dpkg | grep -v extension_$NOM.sqh)" ] ; then
		    LSTEXTP=$LSTEXTP" "$i
		fi
	    done
	    if [ ! -z "$LSTEXTP" ] ; then
		doextension.sh extension_$NOM.sqh $LSTEXTP
	    fi
	    if [ ! -z "$SUDO_USER" ] ; then
		chown $SUDO_USER extension_$NOM.sqh
	    fi
	    ARCHIVE=$(tempfile)
	    rm $ARCHIVE
	    mkdir -p $ARCHIVE
	    (cd $NOM.dir ; tar c var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian* ) | (cd $ARCHIVE ; tar x)
	    mksquashfs $ARCHIVE extension_dpkg_$NOM.sqh  -noappend
	    LSTEXTP=extension_$NOM.sqh
	    for i in $LSTEXT ; do
		if [ ! -z "$(echo $i | grep extension_dpkg | grep -v extension_dpkg_$NOM.sqh)" ] ; then
		    LSTEXTP=$LSTEXTP" "$i
		fi
	    done
	    doextension.sh extension_dpkg_$NOM.sqh $LSTEXTP
	    if [ ! -z "$SUDO_USER" ] ; then
		chown $SUDO_USER extension_dpkg_$NOM.sqh
	    fi
	    rm -Rf $ARCHIVE
	else
	    mksquashfs $NOM.dir extension_$NOM.sqh -noappend
	    LSTEXTP=
	    for i in $LSTEXT ; do
		if [ ! -z "$(echo $i | grep -v extension_dpkg | grep -v extension_$NOM.sqh)" ] ; then
		    LSTEXTP=$LSTEXTP" "$i
		fi
	    done
	    if [ ! -z "$LSTEXTP" ] ; then
		doextension.sh extension_$NOM.sqh $LSTEXTP
	    fi
	    if [ ! -z "$SUDO_USER" ] ; then
		chown $SUDO_USER extension_$NOM.sqh
	    fi

	fi
	if [ ! -z $RAMFS ] ; then 
	    umount $NOM.dir
	    rmdir --ignore-fail-on-non-empty $NOM.dir
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
    ln -s $(pwd)/$BASEFILE.dir /var/tmp/ISN
    cp /etc/resolv.conf /var/tmp/ISN/etc
    chroot $BASEFILE.dir
    rm /var/tmp/ISN
    umount $BASEFILE.dir/proc
    umount $BASEFILE.dir/dev
    if [ ! -z $FINALISE ] ; then
	echo Finalisation de la base
	mv $BASEFILE $BASEFILE.old
	mv $NOMDPKGBASE $NOMDPKGBASE.old
	[ ! -z "$(ls $BASEFILE.dir/var/cache/apt/archives/*.deb)" ] && rm  $BASEFILE.dir/var/cache/apt/archives/*.deb
	mksquashfs $BASEFILE.dir $BASEFILE -wildcards -noappend -e var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian*
	if [ ! -z "$SUDO_USER" ] ; then
	    chown $SUDO_USER $BASEFILE
	fi

	ARCHIVE=$(tempfile)
	rm $ARCHIVE
	mkdir -p $ARCHIVE
	(cd $BASEFILE.dir ; tar c var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian* ) | (cd $ARCHIVE ; tar x)
	mksquashfs $ARCHIVE extension_dpkg-$(cat $BASEFILE.dir/FB).sqh  -noappend
	if [ ! -z "$SUDO_USER" ] ; then
	    chown $SUDO_USER extension_dpkg-$(cat $BASEFILE.dir/FB).sqh
	fi
	rm -Rf $ARCHIVE
	[ ! -z $DESTROY ] && rm -Rf $BASEFILE.dir
    fi
fi
fi