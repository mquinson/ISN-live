#! /bin/sh

# make-stick.sh: adds what's needed to boot the system from a chosen stick
# It should not erase anything from the system (but you should make sure that you have enough room on the key)

# Testing user ID 
uid=$(/usr/bin/id -u)
if [ $uid != "0" ] ; then
  echo "Please make sure to become root before running me" 2>&1 ; 
  exit 1
fi


set -ex

### Initial checkups

if [ -e basesystem.sqh ] ; then
  echo "Base system found, fine."
else
  echo "XXX Unable to fine the base system (basesystem.sqh). Please use make-base.sh first"
  exit 1
fi

if [ -e initrd.gz ] ; then
  echo "initrd found, fine."
else 
  echo "XXX Unable to fine the initrd.gz. Please use make-base.sh first"
  exit 1
fi

echo "XXX Pick the right stick to use"
STICKS=`ls -l /dev/disk/by-id/ | grep " usb-" | awk '{print $11}'  | sed -e 's|^.*\(sd.\)[0-9]*|\1|' | sort -u`

BUTTON="stop"
echo -n > /tmp/USB_message
echo "Stop: Stop the stick creation right away">> /tmp/USB_message
#echo "fake: make a disk image instead of using a real disk">> /tmp/USB_message
for s in $STICKS ; do 
  unset STICK_NAME
  STICK_NAME=`ls -l /dev/disk/by-id/ | grep "$s\$" | sed -e 's/^.*usb-\([^_]*_[^_]*_[^_]*\)_.*$/\1/'`

  unset STICK_SIZE
  STICK_SIZE=`cat /sys/block/$s/size`
  BLOCS=`cat /sys/block/$s/queue/hw_sector_size`
  STICK_SIZE=`expr $STICK_SIZE \* $BLOCS / 1000000`
  TYPE="$s: USB stick $STICK_NAME ($STICK_SIZE Mbytes)"
  BUTTON=$BUTTON","$s
  echo $TYPE >> /tmp/USB_message
done
echo  >> /tmp/USB_message
echo "Clic on the stick to use:"  >> /tmp/USB_message
CHOSEN_STICK=`xmessage -center -print -file /tmp/USB_message -buttons $BUTTON || true` # FIXME: I don't like ignoring the return value here
rm /tmp/USB_message
if [ "$CHOSEN_STICK" = "stop" ] ; then
  exit 1
fi

STICK=/dev/$CHOSEN_STICK
PART=${STICK}1

echo "XXX Copy the data onto the stick $CHOSEN_STICK"
umount mountpoint 2>/dev/null|| true
rm -rf mountpoint
mkdir mountpoint	

mount $PART mountpoint
if [ ! -e mountpoint/boot/grub ] ; then
  mkdir -p mountpoint/boot/grub
fi
if [ -e mountpoint/boot/basesystem.sqh ] ; then
  echo "The base system already exists, do not copy it again (to save time)"
else  
  cp basesystem.sqh mountpoint/boot
fi
cp initrd.gz mountpoint/boot
cp scripts/grub.cfg mountpoint/boot/grub

echo "XXX Install grub onto the stick"
echo "(if it fails with the message 'Your embedding area is unusually small. core.img won't fit in it', try starting gparted to reduce the size of the partition by one Mb, placed at the begining of the disk. One day, that will be automated)"
# http://ubuntuforums.org/archive/index.php/t-1528529.html
grub-install --boot-directory=mountpoint/boot $STICK

umount mountpoint
