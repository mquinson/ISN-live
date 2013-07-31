#!/bin/sh
mkdir -p /home/user/Documents
mkdir -p /oldroot/cdrom/Documents
mount -o bind /oldroot/cdrom/Documents /home/user/Documents

