/* vi: set sw=4 ts=4: */
/*
 *
 * Recherche ficher  François Boisson (2003)
 * (reprise en cas d'echec incorparation CDrom SCSI)
 *
 *   diet gcc -o trouveagreg trouveagreg.c
 *   strip trouveagreg
 *
 */

#include <getopt.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <sys/mount.h>
#include <signal.h>
#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdlib.h>
#include <time.h>
#include <dirent.h>

char FICHIER[]="/cdrom/agreg/agreg";

FILE *in_file, *out_file;
int main(int argc, char **argv)
{
	struct stat stat_buf;
        char media_str[]="/proc/ide/ide0/hda/media";
	char blank[]="";
	char idedrives[]="0a0b1c1d";
	char *cd_device;
	char cd_ide[]="/dev/hda";
	char cd_scsi[]="/dev/scd0";
	char cd_usb[]="/dev/sda1";
	char inbuf[80];
	int trouve;
	int i,x,y,k;
	int nbcdromscsi;
	FILE *f;

// 

	printf("Recherche fichier SQUASHFS (F.Boisson 2007-2009)\n");

	// /proc supposé être monté

	trouve = 0;
	while (argv[1][k] != 0) {
	switch(argv[1][k])
	  {
	  case 'I':
	  case 'i':
	    {
	printf("   Recherche CDrom IDE\n");
	cd_device = cd_ide;
	for (x=0;((x<8) && (trouve == 0));x+=2) {
	   media_str[13]=idedrives[x];
	   media_str[17]=idedrives[x+1];
	   if (f=fopen(media_str,"r")) {
	      if (fgets(inbuf,80,f)) {
	         if (strstr(inbuf,"cdrom")!=NULL) {
		    cd_device[7]=media_str[17];
		    trouve = 1;
	         }
              }
	      fclose(f);
	    }
	// Si trouve = 1, CDrom trouvé
	  if (trouve == 1) {

	    printf("   --> CDrom IDE en [%s]\n",cd_device);
	    chdir("/dev");
	    unlink("cdrom");
	    symlink(cd_device,"cdrom");
	    printf("   Montage CD\n");
	    if (mount ("/dev/cdrom","/cdrom","iso9660",MS_MGC_VAL+MS_RDONLY, blank)) {
	      printf("[RATE]: montage impossible\n");
	      trouve=0;
	    } else printf("   --> réussite\n");
	 // Le CD a pu etre monté
	   if (trouve == 1) {
	     printf("   Recherche de %s\n",FICHIER);
	 /* Open input file */
	     in_file = fopen(FICHIER, "r");
	     if (in_file == NULL) {
	       printf("[RATE]: %s non present\n",FICHIER);
	       trouve = 0;
	     }
	     else {
	 // On sort, le CDrom est monté
		 fclose(in_file);
		 printf("[SUCCES]\n");
		 exit(0);
	     }
	     umount("/cdrom");
	   }
	  }
	}


	if ((x==8) && (trouve == 0)) {
	  printf("[RATE]: pas de CDrom IDE trouvé\n");
	}
	break;
	    }
	  case 'S':
	  case 's':
	    {
	   printf("Recherche de CDrom SCSI et SATA\n");
	   nbcdromscsi = 0;
	   /*
	   if (f=fopen("/proc/scsi/scsi","r")) {
	     while (fgets(inbuf,80,f)) {
	       
	       if ((strstr(inbuf,"Type:") != NULL) && 
		   (strstr(inbuf,"CD-ROM")!=NULL))
		 nbcdromscsi++;
	     }
	     fclose(f);
	   }
	   else printf("[RATE]: Pas de SCSI trouvé\n");

on y va façon brutale 
	   */
	   nbcdromscsi=8;
           if (nbcdromscsi == 0) {
	     printf("[RATE]: pas de CDrom SCSI trouvé\n");
	   }
	   else
	     {
	       trouve=0;
	       // on adapte...
	       cd_device = cd_scsi;
	       for (i=0;((i<nbcdromscsi) && (trouve==0));i++)
		 {
		   // test des différents CDscsi
		   cd_scsi[8] = '0'+i;
		   // rappel: cd_device = cd_scsi
		   printf("   --> CDrom en [%s]\n",cd_device);
		   chdir("/dev");
		   unlink("cdrom");
		   symlink(cd_device,"cdrom");
		   printf("   Montage CD\n");
		   if (mount ("/dev/cdrom","/cdrom","iso9660",MS_MGC_VAL+MS_RDONLY, blank)) {
		     printf("[RATE]: montage impossible\n");
		     trouve=0;
		   } else 
		     {
		       printf("   --> SCSI trouvé\n");
		       trouve = 1;
		     }
		   // Le CD a pu etre monté
		   if (trouve == 1) {
		     printf("   Recherche de %s\n",FICHIER);
		     /* Open input file */
		     in_file = fopen(FICHIER, "r");
		     if (in_file == NULL) {
		       printf("[RATE]: %s non present\n",FICHIER);
		       trouve = 0;
		     }
		     else {
		       // On sort, le CDrom est monté
		       fclose(in_file);
		       printf("[SUCCES]\n");
		       exit(0);
		     }
		     umount("/cdrom");
		   }
		 }
	     }
	   break;
	    }

	  case 'u':
	  case 'U':
	  default:
	    {
	printf("   Recherche USB\n");
	cd_device = cd_usb;
	for (y=0;((y<4) && (trouve == 0));y++) {
	for (x=0;((x<4) && (trouve == 0));x+=1) {

	    printf("   --> Test sur [%s]\n",cd_device);
	    if (mount (cd_device,"/cdrom","vfat",0, blank)) {
	      printf("[RATE]: montage impossible\n");
	      trouve=0;
	    } else 
	      {
		printf("   --> réussite\n");
		trouve=1;
	      }
	 // La clef a pu etre montée
	   if (trouve == 1) {
	     printf("   Recherche de %s\n",FICHIER);
	 /* Open input file */
	     in_file = fopen(FICHIER, "r");
	     if (in_file == NULL) {
	       printf("[RATE]: %s non present\n",FICHIER);
	       trouve = 0;
	     }
	     else {
	 // On sort, le CDrom est monté
		 fclose(in_file);
		 printf("[SUCCES]\n");
		 exit(0);
	     }
	     umount("/cdrom");
	   }
	   cd_usb[7]++;
	  
	}
	cd_usb[7] = 'a';
	cd_usb[8]++;

	}

	}
	    }
	k++;
	  }
	  printf("ECHEC: Pas de CDrom/Clef trouve\n");
	  exit(1);
	
}

