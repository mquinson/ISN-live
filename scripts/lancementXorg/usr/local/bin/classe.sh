#!/bin/sh
rm /tmp/menu-*
for f in *.lnk ; do
    X=`grep "X:" $f | awk '{print $2}'`
#    Y=15
    Y=`grep "Y:" $f | awk '{print $2}'`
    touch /tmp/menu-$X
    if grep -q $Y /tmp/menu-$X ; then
	while grep -q $Y /tmp/menu-$X ; do
	    Y=$[$Y+90]
	done
    fi
    sed -i '1,$s/Y: .*$/Y: '$Y'/' $f
    echo $Y >> /tmp/menu-$X
done