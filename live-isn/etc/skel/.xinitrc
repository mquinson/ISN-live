#!/bin/sh
### Utility Function(s)

# Simple shell grep
stringinfile(){
case "$(cat $2)" in *$1*) return 0;; esac
return 1
}

# same for strings
stringinstring(){
case "$2" in *$1*) return 0;; esac
return 1
}

# Reread boot command line; echo last parameter's argument or return false.
getbootparam(){
stringinstring " $1=" "$CMDLINE" || return 1
result="${CMDLINE##*$1=}"
result="${result%%[ 	]*}"
echo "$result"
return 0
}

# Check boot commandline for specified option
checkbootparam(){
stringinstring " $1" "$CMDLINE"
return "$?"
}
### EOF utility functions

# Read in boot parameters
# This should work, but doesn't with Kernel 2.4.19-rc1
# CMDLINE="$(</proc/cmdline)" This should work, but doesn't with Kernel 2.4.19-rc1
# This works.
CMDLINE="$(cat /proc/cmdline)"

if checkbootparam proxy >/dev/null 2>&1; then
export http_proxy=$PROXY_IP
export ftp_proxy=$PROXY_IP

fi


if ! checkbootparam notux >/dev/null 2>&1; then
xsri --center-x --center-y --emblem=/usr/share/pixmaps/user/tux.png --color=grey19
fi
if checkbootparam notux >/dev/null 2>&1; then
bsetroot -solid grey20
fi

#/usr/bin/dillo /usr/share/f-docs/start.html&

if checkbootparam evilwm >/dev/null 2>&1; then
bsetroot -solid grey20
evilwm
exit
fi

if checkbootparam ion2 >/dev/null 2>&1; then
bsetroot -solid grey20
ion2
exit
fi

xset +fp /usr/share/fonts/X11/75dpi
xset +fp /usr/share/fonts/X11/misc
# xsetbg -onroot -fullscreen /home/user/.fluxbox/tux.png
if [ -f /var/tmp/Xvesa ] ; then
    xmodmap /home/user/.Xmodmap
else
    if [ -f /home/user/preferences ] ; then
	. /home/user/preferences
	if [ ! -z $LAYOUT ] ; then
	    setxkbmap -layout $LAYOUT
	else
	    setxkbmap -layout fr
	fi
    else
	setxkbmap -layout fr
    fi
fi
if [ -d /home/user/.xtdesktop ] ; then
    pushd /home/user/.xtdesktop
    ls *.lnk | xargs -n 1 sed -i -e '1,$s|\$HOME/.xt|.i|g'
    for f in `ls` ; do
	if [ ! -f ../.idesktop/$f ] ; then
	    mv $f ../.idesktop
	fi
    done
    popd
fi
if [ -d /home/user/.idesktop ] ; then
pushd /home/user/.idesktop
/usr/local/bin/classe.sh
popd
fi
xset r on
if which fluxbox ; then fluxbox 
elif which xfce4-session ; then xfce4-session
fi
