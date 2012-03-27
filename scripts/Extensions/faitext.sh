#!/bin/sh
usage()
{
cat << EOF
Utilisation: faiext.sh arguments
 -b base: utilise le fichier base comme base de système de fichiers
 -n nom: nom de l'extension concernée ou du répertoire (nom.dir) correspondant
 -e extension: chargement de l'extension extension 
 -f : finalise l'extension en fabriquant le fichier .sqh à la fin
 -h : usage de la commande
EOF
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

LSTEXT=""
FINALISE=""
while getopts “hb:fn:e:” OPTION
do
     case $OPTION in
         h)
             usage
             exit 1
             ;;
         b)
             BASEFILE=$OPTARG
             ;;
         n)
             NOM=$OPTARG
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

MONTAGE=/var/$(tempfile)
BASE=/var/$(tempfile)
DPKG=/var/$(tempfile)
SUPPORT=/var/$(tempfile)
echo $MONTAGE $BASE $DPKG $SUPPORT | sed -e 's|/var||g' | xargs rm
MONTESQH="mount -o loop -t squashfs "
if [ -z $BASEFILE ] || [ -z $NOM ] ; then
    usage
    exit 1
fi
mkdir -p $MONTAGE
mkdir -p $DPKG
mkdir -p $SUPPORT
mkdir -p $BASE
NOM=$(echo $NOM | sed -e 's/.dir//' | sed -e 's|/$||')
if [ ! -d $NOM.dir ] ; then
    mkdir -p $NOM.dir
fi
$MONTESQH $BASEFILE $BASE
$MONTESQH extension_dpkg-$(cat $BASE/FB).sqh $DPKG
CHAINE=":$DPKG=ro:$BASE=ro"
for ext in $LSTEXT ; do
    EXT=$(basename $ext | sed -e 's/.sqh//')
    mkdir -p $SUPPORT/$EXT
    $MONTESQH $1 $SUPPORT/$EXT
    CHAINE=":$SUPPORT/$EXT=ro:$CHAINE"
done    
mount -t aufs aufs $MONTAGE -o dirs=$NOM.dir=rw$CHAINE 
chroot $MONTAGE
umount $MONTAGE
for f in $(ls $SUPPORT) ; do
    umount $MONTAGE/$f
done
[ -d $SUPPORT§* ] && rmdir $SUPPORT/*
umount $DPKG
umount $BASE
rmdir $BASE $MONTAGE $DPKG
[ -d $SUPPORT ] && rmdir $SUPPORT
if [ ! -z $FINALISE ] ; then
    echo Finalisation de $NOM
    [ ! -z "$(ls $NOM.dir/var/cache/apt/archives/*.deb)" ] && rm  $NOM.dir/var/cache/apt/archives/*.deb
    mksquashfs $NOM.dir extension_$NOM.sqh -wildcards -noappend -e var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian*
    ARCHIVE=$(tempfile)
    rm $ARCHIVE
    mkdir -p $ARCHIVE
    (cd $NOM.dir ; tar c var/lib/apt* var/lib/dpkg* var/lib/aptitude* var/cache/apt* var/cache/debconf* usr/share/lintian* ) | (cd $ARCHIVE ; tar x)
    mksquashfs $ARCHIVE extension_dpkg_$NOM.sqh  -noappend
    rm -Rf $ARCHIVE
# mise en place des dépendances
    LONGUEUR=`ls -l extension_$NOM.sqh | awk '{print $5}'`
    complete  $LONGUEUR
    for ext in $LSTEXT ; do
	EXT=$(basename $ext)
	if (echo $EXT | grep -q  extension_dpkg ) ; then
	    echo $EXT ignorée
	else
	    echo $EXT >> $$NOM.sqh
	fi
    done
    echo $RESULTAT >> $NOM
fi    
