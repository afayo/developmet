
============================================================

#include<sys/types.h>
#include<dirent.h>
#include<unistd.h>
#include<sys/vfs.h>
#include<stdio.h>
#include<time.h>
#include<sys/statfs.h>
#include <sys/stat.h> 
#include <fcntl.h>
#include <errno.h>
#define _LARGEFILE_SOURCE
#define _LARGEFILE64_SOURCE
#define _FILE_OFFSET_BITS 64
  
typedef enum{
	DISK_FORMAT_FAT32=0,
	DISK_FORMAT_NTFS,
	DISK_FORMAT_LINUX
}DISK_FORMAT;


#define	REC_DBG(fmt,args...)	fprintf(stdout,"%s:%d: "fmt,__FUNCTION__,__LINE__,##args)

int RecordGetPid(int stream_index)
{
	FILE *procpt;
	char line[100];
	char nline[100];
	char tmp[9][64];
	char cmd[64];
	pid_t rec_pid;
	int i=0;
	
	snprintf(cmd,64,"ps  | grep  record_save | grep -v grep | grep %d ",stream_index+1);
	//snprintf(cmd,64,"ps  | grep  sample_hision | grep -v grep");
	REC_DBG(" cmd %s \n",cmd);
	procpt = popen(cmd, "r");

	while (fgets(line, sizeof(line), procpt))
	{
		REC_DBG("%s\/",line);
		//update disk capacity info
		while(line[i]==' ')
		{
			i++;
		}
		
		strncpy(nline,line+i,64);
		
		REC_DBG("%s \n",nline);
		//if (sscanf(nline, "%[^ ] %[^ ] %[^ ]  %[^ ]  %[^\n]", tmp[0], tmp[1],tmp[2], tmp[3],tmp[4])  )
		if (sscanf(nline, "%[^ ] %[^ ] %[^ ] %[^ ]  %[^ ] %[^ ] %[^ ] %[^ ] %[^\n]", tmp[0], tmp[1],
			tmp[2], tmp[3],tmp[4],tmp[5],tmp[6],tmp[7],tmp[8]) )
		{
			
			rec_pid = atoi(tmp[0]);
			REC_DBG("tmp[0] : %s rec_pid: %d \n",tmp[0],rec_pid);
			//pSysInfo->vstream_cfg[stream_index][0].rec_info.rec_pid=rec_pid;
			break;
		}
	}
	pclose(procpt);
	return 0;
}

long long GetDiskfreeSpace(char *pDisk)
{
	long long freespace = 0;
	struct statfs disk_statfs;

	if( statfs(pDisk, &disk_statfs) >= 0 )
	{
		freespace = (((long long)disk_statfs.f_bsize  * (long long)disk_statfs.f_bfree)/(long long)1024/(long long)1024);
	}

	return freespace;
}

long long GetDiskusedSpace(char *pDisk)
{
	long long usedspace = 0;;

	struct statfs disk_statfs;

	if( statfs(pDisk, &disk_statfs) >= 0 )
	{
		usedspace = (((long long)disk_statfs.f_bsize * (((long long)disk_statfs.f_blocks) - (long long)disk_statfs.f_bfree)/(long long)1024));
	}
	return usedspace;
}


unsigned long get_file_size(const char *path)  
{  
    unsigned long filesize = -1;      
    struct stat statbuff;  
    if(stat(path, &statbuff) < 0){  
        return filesize;  
    }else{  
        filesize = statbuff.st_size;  
    }  
    return filesize;  
}  

typedef struct _FILE_INFO{
	char name[50];
	char date[15];
	char time[10];
	char size[20];
} FILE_INFO;

static FILE_INFO *pLIST_MEM = NULL;



unsigned long get_largefile_size(const char *path)  
{  
	#if 0
    unsigned long filesize = -1;      
    struct stat statbuff;  
    if(stat64(path, &statbuff) < 0){  
        return filesize;  
    }else{  
        filesize = statbuff.st_size;  
    }  
    return filesize;  
    #endif
    
    struct stat64 finfo;
	struct tm *pTime;
	
    if(!stat64(path,&finfo))
	{
		pTime = localtime((time_t*)&finfo.st_ctime);
		printf("%s\n",path);
		printf("%d/%02d/%02d\n",(1900+pTime->tm_year),( 1+pTime->tm_mon), pTime->tm_mday);
		printf("%02d:%02d:%02d\n",pTime->tm_hour, pTime->tm_min, pTime->tm_sec);
		printf("%lld K \n",((long long)finfo.st_size/(long long)1024));
		/*fprintf(stderr,"%s	%s	%s	%s \n",	pLIST_MEM[i].name,
									pLIST_MEM[i].date,
									pLIST_MEM[i].time,
									pLIST_MEM[i].size);*/
	}
    
}  


int productlargefile(char *file)
{
	  int fd, ret;
	  off_t offset;
	  int total = 4;

	 
	  //OPTION 2:是否有O_LARGEFILE选项
	  fd = open(file,O_RDWR|O_CREAT|O_LARGEFILE, 0644);
	  //fd = open(file, O_RDWR|O_CREAT, 0644);
	  if (fd < 0) {
		perror(file);
		return -1;
	  }
	  offset = (off_t)total*1024ll*1024ll*1024ll;
	  printf("offset=%ll /n", offset);
	 
	  //OPTION 3：是否调用64位系统函数
	  //if (ftruncate64(fd, offset) <0)
	  if (ftruncate(fd, offset) <0)
	  {
		printf("[%d]-ftruncate64 error: %s/n", errno,strerror(errno));
		close(fd);
		return 0;
	  }
	  close(fd);
	  printf("OK/n");
	  return 0;
}



void   main()
{
	struct statfs diskInfo;
	
	time_t   now; 
	struct  tm     *timenow;
	time(&now);
	timenow   =   localtime(&now);
	printf("Local   time   is   %s/n",asctime(timenow));
	printf("Today's date and time: %s\n", ctime(&now));
	printf("%d-%d-%d-%d-%d\n",timenow->tm_year+1900,timenow->tm_mon+1,timenow->tm_mday,timenow->tm_hour,timenow->tm_min);
	printf(" sizeof(DISK_FORMAT) %d \n",sizeof(DISK_FORMAT));
	
	statfs("/media/sdb1",&diskInfo);
	//unsigned long long blocksize = diskInfo.f_bsize;// 每个block里面包含的字节数
    //unsigned long long totalsize = blocksize * diskInfo.f_blocks/(long long)1024;//总的字节数
    
    long long freeDisk;
    long long useSpace;
    freeDisk=GetDiskfreeSpace("/media/sda1");
    useSpace=GetDiskusedSpace("/media/sda1");
    printf("freeDisk = %lld \n",freeDisk);
	printf("useSpace = %lld \n",useSpace);
    //unsigned long long freeDisk = diskInfo.f_bfree*blocksize/(long long)1024; //再计算下剩余的空间大小
	
	printf("diskInfo.f_type == 0x%x \n",diskInfo.f_type);
	
	//unsigned long totalsize=get_file_size("/media/sdb1");
	
	//printf("totalsize = %lu \n",totalsize);
	
	while(1)
	{
		//get_largefile_size("/media/sda1/h264-PGM.mp4") ;
		get_largefile_size("/media/sda1/PGM/PGM1970-01-01-00-24PGM.mp4") ;
		//get_largefile_size("/media/sda1/PGM/PGM1970-01-01-00-24PGM.mp4") ;
		usleep(2000000);
	}
	
	
	//productlargefile("/media/sda1/largefile");
	
}


参考链接：
http://blog.163.com/qimo601@126/blog/static/158220932013921758707/

http://blog.sina.com.cn/s/blog_5c93b2ab0100vhk1.html



=============================================================
