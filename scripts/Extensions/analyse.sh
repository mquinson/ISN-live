#!/bin/sh
# 12 chiffres + un ^J
# analyse une suite d'extensions et sort l'ordre de chargement
#
MAX_LONGUEUR=13
analyse_extension ()
{
eval NOM_$2=$1
#eval echo NOM_$2 = \$NOM_$2
if `tail -c $MAX_LONGUEUR $1 | grep -q -E "^[0-9 ]*$"` ; then
    eval NOMB=\$NOM_$2
#    echo NOMB = $NOMB
    LONGUEUR=`tail -c $MAX_LONGUEUR $NOMB`
    LONGUEUR=`expr $LONGUEUR + 0`
    LONGUEUR_REELLE=`ls -l ${NOMB} | awk '{print $5}'`
    LST=`tail -c $[$LONGUEUR_REELLE - $LONGUEUR] ${NOMB}`
        for f in $LST ; do
	    if `echo $f | grep -q extension_` ; then
		NEXT=$[$2 + 1]
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
	if `echo $LISTE | grep -v -q $i` ; then
	    LISTE=$LISTE" "$i
	fi
    done
    shift
done
echo $LISTE
}

analyse_liste $*