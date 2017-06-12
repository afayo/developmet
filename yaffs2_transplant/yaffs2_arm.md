
相关参考链接：
官方的：
http://www.yaffs.net
http://www.yaffs.net/download-yaffs-using-git 
http://www.yaffs.net/running-yaffs-direct-tests
http://www.yaffs.net/documents
http://www.yaffs.net/documents/yaffs-nand-flash-failure-mitigation
http://www.yaffs.net/yaffs-tuning-and-configuration
http://www.yaffs.net/documents/yaffs-direct-interface
http://www.aleph1.co.uk/gitweb?p=yaffs2.git;a=summary
http://www.yaffs.net/documents/how-yaffs-works

第三方的：
http://blog.csdn.net/pottichu/article/details/4367918
http://blog.csdn.net/flymachine/article/details/6966383
https://en.wikipedia.org/wiki/YAFFS
http://processors.wiki.ti.com/index.php/Special:ListFiles?limit=50&ilsearch=&user=&offset=0056_Schematic.pdf&sort=img_name


移植小技巧：
1，在uboot中如果需要添加自定的宏，可以考虑中顶层的Makefile文件进行添加，通常在顶层Makefile文件添加的宏定义，通过#include<config.h>对于整个工程都是有效的;另外，可以考虑
   在对应configs文件中进行添加修改，但是，这种方法添加的宏，这种方法添加的宏只对局部代码有效,同样，需要#include<configs/ti8148_ipnc.h>。uboot顶层的Makefile文件中，定义
   定义类型开发版的东西,其中，有这么一句	@$(MKCONFIG) -a ti8148_ipnc arm arm_cortexa8 ti8148_ipnc ti ti81xx, 这句话是有一定用处的，具体可以参考顶层的mkconfig文件。  
2，在移植内核的时候，如果需要添加全局的自定义宏，可以考虑在某个模块或者文件夹的Kconfig文件上进行添加修改，此方法添加的宏对于整个Kernel代码都是有效果的，
   具体修改的地方，用户自己决定。


关于ubifs/jffs2/yaffs个人感想
jffs2 文件系统是比较老的，一起用的比较多，该文件系统最初设计用在nor flash上，但也可以用在nand flash上，不过该文件系统对于直接掉电的情况，容易出现flash内的数据损坏，
造成程序运行异常。该文件系统每一页数据需要8Bytes clean marker数据，该数据存储在oob（out of bank）空闲区域oob_free上，linux系统默认支持。
ubifs文件系统也是基于mtd驱动架构的，新的linux系统内核支持该文件系统，该文件系统可以说是jffs2的升级版，相比jffs2,各方面性能上都有较大的提升。此外，该文件系统貌似不需要tag之类的
信息，也就是说不需要向yaffs文件系统的yaffsTag或者jffs2文件系统的cleam marker这样的数据。
yaffs 文件系统是独立的代码管理，linux系统内核默认不支持，需要移植。该文件系统是专门为nand flash系统设计的，具有防掉电程序损坏的功能;该文件系统需要yaffsTag信息，并需要将
该信息写到oob的空闲区域oob_free上。移植过程大概是：1，下载源码，建议根据内核的版本时间选择对应时间段的yaffs源码;2,给内核打上yaffs补丁;3,运行make menu，进入内核配置页面，
增加yaffs支持选项，编译内核;4,修改makeyaffs2image源码，支持对应平台的flash;5,烧写对应固件到内核中去。


一， 移植yaffs到嵌入式开发8148版上
环境：
内核：Linux version 2.6.37
nand flash:MT29F2G16ABAEA  256M 16bit (通过datasheet<m69a_2gb_ecc_nand.pdf>，可以找到对应参数 Block:128KB Page:2KB OOB:64B)   
CPU: 8148
内存: 1GB
默认的文件系统：ubifs 
内核默认的ECC算法是：BCH8

移植的默认规则是：不同的源码库，尽量找时间轴上相近的代码，或者，彼此变化相对较小的代码

    在移植yaffs之前，由于对于yaffs系统没什么概念，所以最先想到的是看一下TI官方的手册上有没有相关的说明，仔细找了一下，发现了一个pdf《IPNC_RDK_NAND_ECC_Guide.pdf》,
该文档主要是说默认的IPNC_SDK包(IPNC_RDK_DM812x_DM385_Version3.5.0.tar.gz)不支持jffs2，其中分析了原因，主要是因为nand flash中的每页上的OOB大小不够,详见如下：
Supporting BCH8 with JFFS2 is not possible because of shortage of OOB area.
.Total OOB Bytes --- 64 Bytes (for every 2048 bytes (512 * 4))
.JFFS2 clean marker requires 8 bytes. Remaining OOB Bytes = 56 bytes (64 – 8)
.ECC requires 14 bytes for every 512 bytes of data. Total ECC bytes = 56 Bytes(14 * 4).
.Remaining OOB Bytes = 0 byte (56 – 56)
.Manufactures bad block marking requires 2 bytes which is not available.
.This shortage (-2) is the main reason is the issue with using JFFS2 + 8-Bit BCH ECC.

关于OOB的小知识:
    通常在nand flash中，由于该类型的flash的特性，导致容易出现bit位反转的现象，所以，通常情况下，每一页数据后面就带有一小块冗余的空间，这个冗余的空间的就叫OOB（out of band）.
OOB的大小根据flash类型不同而不同，通常64B（2K page），32B（1K page）,具体可以参考对应的flash datasheet。
    知道OOB概念了，那么在OOB空间上通常是存放什么数据呢？这个答案就是，其通常存放坏块标志（2B），页数据的ECC纠错码，文件系统的状态;
	其中，文件系统的状态是指在不同类型的文件系统中，会需要一些特定数据来表示对象的状态，这样说可能会比较抽象，具体举个例子：如果系统采用的是jffs2,那么对于每一页的数据，
JFFS2文件系统都要求8 Bytes OOB空间数据来表示clean marker;又例如，文件系统如果是采用yaff2（通常用于页大小大于等于1K的nand flash）,那么对于页大小为2K的flash，
则需要42 Bytes OOB空间数据来存储yaffstag;页大小为1K的flash，则需要30 Bytes OOB空间数据来存储yaffstag标志,具体解释可以查看yaffs官方文档.
	页数据的ECC纠错码是指由对应的ECC算法生成的，通常情况ECC算法是flash驱动选定。通常uboot和kernel两个地方都涉及ECC算法，这两个地方的ECC算法是独立，通常建议是uboot和内核的ECC
算法是一样，具体的做法是移植内核的nand驱动中ECC算法到uboot中。
	其中，内核nand flash驱动代码，涉及文件有driver/mtd/nand/nand_base.c,该文件关注struct nand_ecclayout结构体的初始化， mtd->layout, chip->ecc.layout, mtd->oobavail,
chip->ecc.oobavail,chip->ecc.total , chip->ecc.steps ,  chip->ecc.bytes, mtd->read_oob,mtd->write_oob  ,nand_get_flash_type()函数  ; 
driver/mtd/nand/omap2.c(不同平台对应的nand特定代码), 需要关注的是 struct nand_ecclayout 结构体的初始化， ecc_opt,omap_oobinfo.eccbytes, mtd.erasesize ,mtd.writesize,     
mtd.oobsize ,oobfree->offset, 注意oobfree->offset的值需要根据具体应用来确定，通常情况下，前两个字节保留用于坏块标志，举个例子：2Kpage，64B的OOB，前两个字节用于坏块标志,flash
厂商出产芯片时，通常需要对flash测试，并将坏块标志出来，采用方法是在坏块的第一页/第二页的OOB数据空间上做个标志，具体位置就是OOB的第一个字节0xff（x8）或者第一和第二个字节0xffff（x16），接下来
用于可以自行选择是先存放ECC纠错码还是先存放文件系统状态（yaffstag或者jffs clean marker）,这两个谁先谁后没有关系，需要注意的是：oobfree是指除了ECC纠错码和2字节块标志后剩下的OOB
空间，oobfree->offset是指OOB空间上第一个字节开始算的偏移量， oobfree->length,则是可以用来存储文件系统状态的字节书长度。 
arch/arm/mach-omap2/board-flash.c(特定平台flash包括nor和nand初始化代码)，该文件关注 ecc_opt选项配置 ;arch/arm/mach-omap2/board-ti8148ipnc.c(特定硬件平台的板级初始化文件)
	其中，uboot的nand flash驱动，具体的需要的文件，可以结合对应目录下的Makefile文件查看，包括的文件有driver/mtd/nand/nand_base.c，该文件nand驱动通用的文件，主要关注chip->ecc结构体的填充。 
driver/mtd/nand/nand.c,该文件是通用函数,用于flash的初始化。 
driver/mtd/nand/ti81xx_nand.c, 该文件的特定平台的flash初始化文件，根据特定的flash进行配置，主要关注的是：board_nand_init,__ti81xx_nand_switch_ecc() 对struct nand_chip *nand 结构体的成员的
填充，特别是对于该结构体的ecc结构体的填充。   
调用顺序是：nand_init() (arch/arm/lib/board.c文件中的start_armboot函数 ) ->nand_init_chip()(driver/mtd/nand/nand.c文件中的nand_init()函数)->board_nand_init(driver/mtd/nand/ti81xx_nand.c文件中的函数,此文件是特定平台的文件), nand_scan(driver/mtd/nand/nand_base.c文件中的函数) 

下面讲一下uboot中一个关键的结构体   struct nand_ecclayout,具体定义如下 
struct nand_ecclayout {
	uint32_t eccbytes; //ecc纠错码的字节数
	uint32_t eccpos[128]; //ecc纠错码在OOB数据空间上的文件，具体OOB大小参考对应的flash数据手册
	uint32_t oobavail;   // 剩余空闲的OOB字节数，通常的大小=总的OOB字节数-最开始的两个字节（用来表示坏块标志）-ecc纠错码字节数,可用于存储yaffstag，或者jffs2 clean marker,等信息。
	struct nand_oobfree oobfree[MTD_MAX_OOBFREE_ENTRIES]; //剩余字节数的长度，和在OOB数据空间上的位置，通常是用offset的偏移量表示。 
};
#define GPMC_NAND_HW_ECC_LAYOUT {\
	.eccbytes = 12,\    //表示 ecc纠错码总共有12个字节数
	.eccpos = {2, 3, 4, 5, 6, 7, 8, 9,\ //只是12个ecc纠错码在OOB空间上的位置，通过下标索引值表示
		10, 11, 12, 13},\
	.oobfree = {\     
		{.offset = 14,\    //只是剩余空闲的OOB空间的开始位置，通用偏移量表示
		 .length = 50 } } \ //指示剩余空闲的OOB字节总数
}

需要注意的是：类似的,在内核代码中，也可以找到类似这样的一个结构体，一直yaffs2文件系统，修改这个结构体很关键，同样，在mkyaffs2image工具的源码中，这个结构体也要一致，否则，通过mtd-utils工具flash_eraseall和nandwrite烧写，或者通过uboot命令nand write.yaffs少些的yaffs2固件会校验失败，导致文件系统不能正常挂在，进而导致系统启动异常。
建议新建一个文件夹，里面放一个文件，将该文件夹生成一个yaffs2固件，烧写到flash上去调试，直接对比oob数据。需要用到的工具有，winhex，nandwrite，nanddump，nand dump.oob,
在linux系统下，用nandwrite烧写yaffs2固件，用nanddump查看具体的oob数据，
具体用法是：
======================================================================
linux 系统下：
flash_eraseall -q /dev/mtd10 // 擦除flash分区数据，将对应分区上的数据，全部变成1,因为默认没有数据的情况下，nand flash上面是全1的，写入数据是将1变成0。  

nandwrite -o -s 0x20000 /dev/mtd10 minifs_2k_1bit.yaffs2 // 写入yaff2固件，注意为了调试方便，建议 minifs_2k_1bit.yaffs2 固件可以通过新建一个文件夹，里面新建一个文件，然后将该
														// 文件夹生成yaffs2固件，文件夹大小控制在两到三页大小。方便nanddump查阅oob数据。

nanddump -p -l 4096 -o -f hex_mtd10_uboot.txt /dev/mtd10

nand write.yaffs烧写完后，系统挂在启动，烧写进去的uboot的oob数据是否正常查看 oob数据

=======================================================================

===================================================================================================================
uboot 系统下：
在系统选用了硬件ecc生成纠错码的情况下，nand write 的相关命令会通过相应的 硬件ecc算法计算出ecc纠错码，并写入到对应的oob区域上去，
注意：通常makeyaffs2image工具只负责生成yaffstag信息，该tag信息中包含有yaffs文件系统自带的ecc纠错码，但是该纠错码通常情况下是不会
用到的，如果想启用yaffs文件系统在yaffsTag中自带的ecc纠错码，那么需要如下条件：
1,关闭uboot和内核的ecc 算法，包括软件和硬件ecc，也就是说关闭uboot和内核flash驱动中的ecc算法。
2,开启yaffs文件系统的选项，让yaffs文件系统自己做ecc校验工作。
--- Miscellaneous filesystems
*   Lets Yaffs do its own ECC    

nand_write_skip_bad（）该函数会对写入的数据添加对应的ECC纠错码，同时该函数传入的长度参数是实际的页数据长度（不包括OOB的数据长度）
通过winhex软件打开固件对比oob数据，发现此处的ecc部分自动被覆盖了。
http://blog.chinaunix.net/uid-11911430-id-2801526.html

通过制作一个较小的文件系统几页大小的数据，通过nand dump.oob xxx 
下面是从0xd4c0000地址开始的页
Page 0d4c0800 dump:
OOB:
	ff ff 00 10 00 00 01 01
	00 00 00 00 00 00 ff ff
	00 00 25 00 00 00 00 00
	00 00 ff ff ff ff ff ff
	ff ff ff ff ff ff ff ff
	bd 42 0f 00 00 00 00 00
	00 00 00 00 ff ff ff ff
	ff ff ff ff ff ff ff ff
TI8148_IPNC#nand dump.oob d4c1000
Unknown command 'nand' - try 'help'
TI8148_IPNC#nand dump.oob d4c1000
Page 0d4c1000 dump:
OOB:
	ff ff 00 10 00 00 01 00
	00 00 00 00 00 00 ff ff
	00 00 30 00 00 00 05 00
	00 00 05 00 00 00 ff ff
	ff ff ff ff ff ff ff ff
	5b 5b 88 00 00 00 00 00
	00 00 00 00 ff ff ff ff
	ff ff ff ff ff ff ff ff
TI8148_IPNC#nand dump.oob d4c1800
Page 0d4c1800 dump:
OOB:
	ff ff 00 10 00 00 02 01
	00 00 00 00 00 00 ff ff
	00 00 26 00 00 00 00 00
	00 00 ff ff ff ff ff ff
	ff ff ff ff ff ff ff ff
	72 8d 1e 00 00 00 00 00
	00 00 00 00 ff ff ff ff
	ff ff ff ff ff ff ff ff
TI8148_IPNC#nand dump.oob d4c2000
Page 0d4c2000 dump:
OOB:
	ff ff 00 10 00 00 02 01
	00 00 01 00 00 00 78 04
	00 00 1a 00 00 00 05 00
	00 00 fa ff ff ff ff ff
	ff ff ff ff ff ff ff ff
	88 88 11 05 fa 96 98 67
	3c 00 00 00 ff ff ff ff
	ff ff ff ff ff ff ff ff

hisilicon # nand dump.oob f600000
Page 0f600000 dump:
OOB:
	ff ff a9 a5 aa ff ff ff
	ff ff ff ff ff ff ff ff
	cf cf f3 c0 ff ff 00 10
	00 00 01 01 00 00 01 00
	00 00 81 00 00 00 0f ff
	ff ff 08 00 00 00 08 00
	00 00 ff ff ff ff ff ff
	ff ff ff ff ff ff ff ff
在海思平台上也发现uboot写入的数据，会自动添加上ecc校验码。

  
nand write：向Nand Flash写入数据，如果NandFlash相应的区域有坏块，则直接报错。
nand write.e: 向Nand Flash写入数据减肥时会时行ECC校验，如果NandFlash相应的区域有坏块，可以跳过坏块。
nand write.jffs2：向Nand Flash写入jffs2镜像到相应的分区。
nand write.yaffs：同理，实现yaffs文件系统镜像的烧写，这个命令不一定所有版本的u-boot支持，有些版本可能需要自己手动添加

=========================================================================================================================

==============================================
mkyaffs2image.c文件中关键的几个地方

#define MAX_OBJECTS 20000 //总的文件数，根据实际可以调整
static int chunkSize = 2048; //flash页大小，页2k为2048,页1k为1024,页512为512,注意yaffs2只支持大于等于1k的页大小
static int spareSize = 64;  // oob空间大小，页2k为64Bytes，页大小为1k的为32Bytes

static int write_chunk(__u8 *data, __u32 objId, __u32 chunkId, __u32 nBytes)
{
	......
	.....
    yaffs_PackTags2(&pt, &t, 1); //生成yaffstag数据

	//接下来就是关键了，需要根据内核中oob结构，将，yaffstag数据写到
	//oob空间的空闲地址oobfree上去，注意：oobfree结构的offset和length两个变量，不同的平台可能不一样，
	//注意具体的数据的ECC，有uboot和内核自己选择生存，如果想用yaffs做ECC
	//
    /*hisilicon_nandmtd2_pt2buf(oobbuf, &pt);	*/
	my_shuffle_oob(oobbuf, &pt);	


    return write(outFile, oobbuf, spareSize);

}


下面函数负责将yaffstag信息写入到ooB空闲区域上去对应地址。
static void my_shuffle_oob(unsigned char * buffer, yaffs_PackedTags2 * pt_tmp)
{
	struct nand_oob_free oobfree_2k_1bit[] =
	{
		{2, 38}, {52,12},
	};

	int cnt=sizeof(oobfree_2k_1bit)/sizeof(struct nand_oob_free);
	int  tag_len= sizeof(yaffs_PackedTags2);
    unsigned char * ptab = (unsigned char *)pt_tmp; /* packed tags as bytes */

	/*printf("cnt = %d tag_len %d \n",cnt,tag_len );*/

    memset(buffer, 0xFF, spareSize);

	if(oobfree_2k_1bit[0].length < tag_len)
	{
		memcpy(buffer+oobfree_2k_1bit[0].offset, ptab, oobfree_2k_1bit[0].length);
		memcpy(buffer+oobfree_2k_1bit[1].offset, ptab+oobfree_2k_1bit[0].length, tag_len - oobfree_2k_1bit[0].length);

	}
	else{

		memcpy(buffer+oobfree_2k_1bit[0].offset, ptab, tag_len);

	}

}

===============================================

小感：
1,在进行flash分区划分的时候，强烈建议以最小擦除块大小为最小单位划分flash分区。
2,在调试写入读出数据的模块，最直接的调试方法是把数据读写输出来和原始数据对比，直接可以看出是什么问题，如：flash驱动调试，网卡驱动调试，串口驱动调试，等等
  该方法在驱动调试中常用，效率较高。而在调试程序运行过程或者跟踪触发条件是，则通常主要是在代码中添加打印信息，进行调试跟踪。最近发现coredump文件挺有用的。

