#!/bin/sh
#
# doextension.sh extension extension1 extension2 ... extensionp
# installe les dépendances à la fin
#
complete ()
{
    TEST=1$1
    if [ $TEST -lt 1000000000000 ] ; then
	complete "0$1"
    else
	RESULTAT=$1
    fi
}
LONGUEUR=`ls -l $1 | awk '{print $5}'`
complete  $LONGUEUR
FICHIER=$1

while [ ! -z $2 ] ; do
    echo $2 >> $FICHIER
    shift
done
echo $RESULTAT >> $FICHIER
