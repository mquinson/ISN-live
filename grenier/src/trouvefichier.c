/* vi: set sw=4 ts=4: */
/*
 *
 * Recherche ficher  François Boisson (2003-2010)
 * (reprise en cas d'echec incorparation CDrom SCSI)
 *
 *   diet gcc -o trouvefichier trouvefichier.c
 *   strip trouvefichier
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
/*
  3 arguments:
  trouvefichier USI pointdemontage chemindufichier 
  mode verbeux, donner 4 arguments trouvefichier USI pointdemontage chemindufichier q
*/
int main(int argc, char **argv)
{
  char *FICHIER;
  char *MONTE;
  FILE *in_file, *out_file;
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
  int taille;
  int i,x,y,k;
  int nbcdromscsi;
  FILE *f;
  int bavard=0;
  char CDROM[]="/dev/xxxxxxxxxxxxxxxxxxxxxxxxxxx";
  // 
  bavard = (argc > 4);
  taille=strlen(argv[2])+strlen(argv[3])+16;
  FICHIER=malloc(taille);
  FICHIER[0]=0;
  MONTE=malloc(taille);
  MONTE[0]=0;
  if (argv[2][0] != '/')
    {
      strcat(FICHIER,"/");
      strcat(MONTE,"/");
      taille--;
    }
  taille -= strlen(argv[2]);
  strcat(FICHIER,argv[2]);
  strcat(MONTE,argv[2]);
  taille -= strlen(argv[3]);
  strcat(FICHIER,"/");
  strcat(FICHIER,argv[3]);
  printf("Recherche fichier %s sur %s (F.Boisson 2007-2009)\n",FICHIER,MONTE);
  // /proc supposé être monté
  
  trouve = 0;
  while (argv[1][k] != 0) {
    switch(argv[1][k])
      {
      case 'I':
      case 'i':
	{
	  if (bavard) printf("   Recherche CDrom IDE\n");
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
	      
	      if (bavard) printf("   --> CDrom IDE en [%s]\n",cd_device);
	      /*
	      chdir("/dev");
	      unlink("cdrom");
	      symlink(cd_device,"cdrom");
	      */
	      strncpy(CDROM,cd_device,32);
	      if (bavard) printf("   Montage CD\n");
	      if (mount (CDROM,MONTE,"iso9660",MS_MGC_VAL+MS_RDONLY, blank)) {
		if (bavard) printf("[RATE]: montage impossible\n");
		trouve=0;
	      } else if (bavard) printf("   --> réussite\n");
	      // Le CD a pu etre monté
	      if (trouve == 1) {
		if (bavard) printf("   Recherche de %s\n",FICHIER);
		/* Open input file */
		in_file = fopen(FICHIER, "r");
		if (in_file == NULL) {
		  if (bavard) printf("[RATE]: %s non present\n",FICHIER);
		  trouve = 0;
		}
		else {
		  // On sort, le CDrom est monté
		  fclose(in_file);
		  printf("[SUCCES] %s trouve sur %s\n",FICHIER,CDROM);
		  exit(0);
		}
		umount(MONTE);
	      }
	    }
	  }
	  
	  
	  if ((x==8) && (trouve == 0)) {
	    if (bavard) printf("[RATE]: pas de CDrom IDE trouvé\n");
	  }
	  break;
	}
      case 'S':
      case 's':
	{
	  if (bavard) printf("Recherche de CDrom SCSI et SATA\n");
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
	    else if (bavard) printf("[RATE]: Pas de SCSI trouvé\n");
	    
	    on y va façon brutale 
	  */
	  nbcdromscsi=8;
	  if (nbcdromscsi == 0) {
	    if (bavard) printf("[RATE]: pas de CDrom SCSI trouvé\n");
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
		  if (bavard) printf("   --> CDrom en [%s]\n",cd_device);
		  strncpy(CDROM,cd_device,32);
		  /*
		  chdir("/dev");
		  unlink("cdrom");
		  symlink(cd_device,"cdrom");
		  */
		  if (bavard) printf("   Montage CD\n");
		  if (mount (CDROM,MONTE,"iso9660",MS_MGC_VAL+MS_RDONLY, blank)) {
		    if (bavard) printf("[RATE]: montage impossible\n");
		    trouve=0;
		  } else 
		    {
		      if (bavard) printf("   --> SCSI trouvé\n");
		      trouve = 1;
		    }
		  // Le CD a pu etre monté
		  if (trouve == 1) {
		    if (bavard) printf("   Recherche de %s\n",FICHIER);
		    /* Open input file */
		    in_file = fopen(FICHIER, "r");
		    if (in_file == NULL) {
		      if (bavard) printf("[RATE]: %s non present\n",FICHIER);
		      trouve = 0;
		    }
		    else {
		      // On sort, le CDrom est monté
		      fclose(in_file);
		      printf("[SUCCES] %s trouve sur %s\n",FICHIER,CDROM);
		      exit(0);
		    }
		    umount(MONTE);
		  }
		}
	    }
	  break;
	}
      
      case 'u':
      case 'U':
      default:
	{
	  if (bavard) printf("   Recherche USB\n");
	  cd_device = cd_usb;
	  for (y=0;((y<4) && (trouve == 0));y++) {
	    for (x=0;((x<7) && (trouve == 0));x+=1) {
	      
	      if (bavard) printf("   --> Test sur [%s]\n",cd_device);
	      if (mount (cd_device,MONTE,"vfat",0, blank)) {
		if (bavard) printf("[RATE]: montage impossible\n");
		trouve=0;
	      } else 
		{
		  if (bavard) printf("   --> réussite\n");
		  trouve=1;
		}
	      // La clef a pu etre montée
	      if (trouve == 1) {
		if (bavard) printf("   Recherche de %s\n",FICHIER);
		/* Open input file */
		in_file = fopen(FICHIER, "r");
		if (in_file == NULL) {
		  if (bavard) printf("[RATE]: %s non present\n",FICHIER);
		  trouve = 0;
		}
		else {
		  // On sort, le CDrom est monté
		  fclose(in_file);
		  printf("[SUCCES] %s trouve sur %s\n",FICHIER,cd_device);
		  exit(0);
		}
		umount(MONTE);
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
  printf("[ECHEC] %s non trouve\n",FICHIER);
  exit(1);
  
}

