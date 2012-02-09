#!/bin/sh
# 12 chiffres + un ^J
# analyse une suite d'extensions et sort l'ordre de chargement
#
MAX_LONGUEUR=13
analyse_extension ()
{
NOM[$2]=$1
if `tail -c $MAX_LONGUEUR $1 | grep -q -E "^[0-9 ]*$"` ; then
    LONGUEUR=`tail -c $MAX_LONGUEUR ${NOM[$2]}`
    LONGUEUR=`expr $LONGUEUR + 0`
    LONGUEUR_REELLE=`ls -l ${NOM[$2]} | awk '{print $5}'`
    LST=`tail -c $[$LONGUEUR_REELLE - $LONGUEUR] ${NOM[$2]}`
        for f in $LST ; do
	    if `echo $f | grep -q extension_` ; then
		unset TAB[$[$2 +1]]
		analyse_extension $f $[$2 + 1]
		TAB[$2]="${TAB[$2]} ${TAB[$[$2 + 1]]}"
	    fi
	done
fi
TAB[$2]="${TAB[$2]} ${NOM[$2]}"
}

analyse_liste ()
{
LISTE=""
while [ ! -z $1 ] ; do
    analyse_extension $1 0
    RES=${TAB[0]}
    for i in $RES ; do
	if `echo $LISTE | grep -v -q $i` ; then
	    LISTE=$LISTE" "$i
	fi
    done
    shift
done
echo $LISTE
}

analyse_liste $*