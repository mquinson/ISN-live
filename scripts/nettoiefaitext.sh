#!/bin/sh
if [ -z "$SUDO_COMMAND" ] ; then
    sudo nettoiefaitext.sh $*
else
LIGNE=$(mount | grep aufs | grep /var/tmp | awk '{print $3}')
if [ ! -z "$LIGNE" ] ; then
    for i in $LIGNE ; do
	echo demontage de $i
	umount $i
    done
fi
LIGNE=$(mount | grep "/var/tmp/file.*/extension.*"  | awk '{print $3}')
if [ ! -z "$LIGNE" ] ; then
    for i in $LIGNE ; do
	echo demontage de $i
	umount $i
    done
fi
LIGNE=$(mount | grep "/var/tmp/file.*" | awk '{print $3}')
if [ ! -z "$LIGNE" ] ; then
    for i in $LIGNE ; do
	echo demontage de $i
	umount $i
    done
fi
fi