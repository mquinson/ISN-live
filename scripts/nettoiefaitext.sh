#!/bin/sh
if [ -z "$SUDO_COMMAND" ] ; then
    sudo nettoiefaitext.sh $*
else
if [ "z$1" = "zK" ] ; then
    PS=$(lsof | grep /var/tmp/file | awk '{print $2}' | sort -u)
    kill $PS
    kill -9 $PS
    sleep 3
else if [ "z$1" = "zD" ] ; then
    rm /var/tmp/file*
    rm -R /var/tmp/file*
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
fi
fi
