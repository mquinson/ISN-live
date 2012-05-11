#!/bin/sh
NOM=/tmp/B_`date +"%s"` 
xmessage "Sauvegarde du repertoire en cours" -center -buttons "Patientez..."&
if [ ! -f /oldroot/ramdisk/home/.clefcodage ] ; then
    cd /oldroot/ramdisk/home/${USER}
    sudo rsync  -rltpD -q  --del --exclude=".*" . /oldroot/cdrom/home/
    cat liste | awk '{print "sudo rsync -P -rltpD  --del "$1" /oldroot/cdrom/home/"}' | sh
    mkdir -p $NOM
    find . -type l | awk '{print "tar c  \""$0"\" | (cd '$NOM' ; tar x)"}' | sh
    sudo bash -c 'find . -printf "chmod %m \"%p\" 2>/ramdisk/dev/null\n" > /oldroot/cdrom/droitshome.txt'
    cd $NOM
    find . | cpio -o -H newc > /tmp/liens.cpio 
    cd /tmp
    rm -Rf $NOM
    sudo mv liens.cpio /oldroot/cdrom/
    sync
    killall xmessage
else
    cd /oldroot/ramdisk/home/${USER}/public
    sudo rsync  -rltpD -q  --del --exclude=".*" * /oldroot/cdrom/home/
    sudo bash -c 'find . -printf "chmod %m \"%p\" 2>/ramdisk/dev/null\n" > /oldroot/cdrom/droitshome.txt'
    mkdir -p $NOM
    find . -type l | awk '{print "tar c  \""$0"\" | (cd '$NOM' ; tar x)"}' | sh
    cd $NOM
    find . | cpio -o -H newc > /tmp/liens.cpio 
    cd /tmp
    rm -Rf $NOM
    sudo mv liens.cpio /oldroot/cdrom/
    cd /oldroot/ramdisk/home/
    sudo tar cf home.tar  --exclude=${USER}/public .clefcodage ${USER}
    sudo bcrypt home.tar
    sudo mv home.tar.bfe /oldroot/cdrom
    sync
    killall xmessage
fi
xmessage "Sauvegarde finie, menu de fin de session dans 1 seconde" -center -timeout 1 
xfce4-session-logout.real
