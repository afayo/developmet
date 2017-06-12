

    

最近在处理嵌入式系统升级和程序固件如何长时间保证不损坏，发现升级和系统固件的存储需要有个策略，主要分为两步，
一个应用程序打包和文件系统的可读写挂载，为了让程序固件长时间不损坏，建议采用文件系统只读和应用程序固件只读，
对于应用中需要用到可读写目录，可以统一分配一个固定的nand分区，在同一个可读写的分区上进行读写。
同时，为了升级的简便性和可靠性，最好采用一个最小文件系统来作为升级系统的根文件系统，
这样可以可靠的保证升级原来的根文件系统、内核、应用等等。

在使用ubifs文件系统的过程中，需要了解ubifs文件系统相关知识，这些可以参考《ubifs文件系统.zip 》，下面主要讲述，在这个过程中主要遇到的问题，

首先是：mkfs.ubifs命令，该命令属于mtd-utils工具，主要用于生成ubifs文件系统固件。

mkfs.ubifs -r </path/to/your/rootfs/tree> -m <min io size> -e <LEB size> -c <Eraseblocks count> -o </path/to/output/ubifs.img>
如下：  
mkfs.ubifs -r minifs -F -o ./minifs.img -m 2048 -e 126976 -c 90

-r :表示需要生成ubifs固件的目录
-F :表示自动填充剩下的空间，对应uboot命令烧写根文件系统，如：nand write 写入的固件，在生成的时候，一定要添加上-F选项
-o ：表示要输出的固件名
-m ：nandflash的页大小，2048字节
-e ：ubifs 的 LEB块，UBI is a “volume manager” and maps physical  erase blocks (PEB) to logical erase blocks (LEB). 
The LEBs are smaller than the  PEBs because of meta-data and headers.他们的关系是：
(int((Subpage_size + Page_size) / Page_size))  * Page_size
实际使用中，发现是保留了2个page大小，所以LEB的大小是 128kB - 2 * 2048B=126976B
-c ：表示多少个擦除块，这里可以保留1到2个擦除块，使用者可以根据具体使用效果进行调整。此处总的擦除块是96个（12M），但是只使用90个擦除块
具体的分析信息可以，通过linux系统命令查看，不过前提是目标嵌入式平台已经跑起来了，这里建议通过nfs挂在，将嵌入式平台运行起来，通过mtdinfo命令，
查看不同mtd块的信息，如下
root@dm814x-evm:~# cat /proc/mtd 
dev:    size   erasesize  name
mtd0: 00020000 00020000 "U-Boot-min"
mtd1: 00240000 00020000 "U-Boot"
mtd2: 00020000 00020000 "U-Boot Env"
mtd3: 00440000 00020000 "Kernel"
mtd4: 06900000 00020000 "File System"
mtd5: 00c00000 00020000 "Data"
mtd6: 03500000 00020000 "File System2"
mtd7: 00c00000 00020000 "Reserved"
mtd8: 00c00000 00020000 "mini_roofs"
mtd9: 00c00000 00020000 "mnt"
mtd10: 02b40000 00020000 "tmp"

通过cat /proc/mtd 查看mtd分区信息

通过mtdinfo -u /dev/mtdX，查看对应分区的具体参数，包括page大小，子页大小，擦除块个数等信息。
 
root@dm814x-evm:~# mtdinfo  -u /dev/mtd8
mtd8
Name:                           mini_roofs
Type:                           nand
Eraseblock size:                131072 bytes, 128.0 KiB
Amount of eraseblocks:          96 (12582912 bytes, 12.0 MiB)
Minimum input/output unit size: 2048 bytes
Sub-page size:                  512 bytes
OOB size:                       64 bytes
Character device major/minor:   90:16
Bad blocks are allowed:         true
Device is writable:             true
Default UBI VID header offset:  512
Default UBI data offset:        2048
Default UBI LEB size:           129024 bytes, 126.0 KiB
Maximum UBI volumes count:      128

第二个是ubinize命令，该命令是将mkfs.ubifs生成的ubifs固件转换为UBI格式，UBI是基于MTD架构，在内核的MTD架构中，具有较好的支持。
# ubinize -vv -o <output image> -m <min io size> -p <PEB size>KiB <configuration file>
如：
ubinize -o $(TFTP_HOME)/$(BOARD_TYPE)_minifs.bin -m 2048 -p 128KiB -s 512 -O 2048 $(IPNC_INSTALL_DIR)/minifs.cfg

-o: 指示输出的UBI固件名
-m：nandflash的页大小，此处为2048Bytes
-p：表示物理擦除块大小（PEB），此处为128KiB，
-s：表示子页大小
-O：offset if the VID header from start of thephysical eraseblock，此处指定为页的大小2048bytes

===========================================================================
补充：

file xxx 查看文件类型和需要的基本库，以及是否strip了

查看函数库或者可执行程序的体系架构
xxx-readelf -A xxx.lib
xxx-readelf -A xxx.bin

查看可执行程序所依赖的静态库
xxx-readelf -d xxx.bin

挂在命令：
mount -t ubifs ubi4:recovery /opt

smart_mount UBIFS /dev/mtd8 /opt/ minifs

烧写命令：

time dd if=/dev/sda1 of=./test.dbf bs=8k count=10240

dd if=/dev/zero of=test.dbf bs=1M count=30

dd if=HS-V6Pro-1024MB_minifs.bin of=/dev/mtd8 bs=2048

如果是要作为根文件系统，在linux系统运行过程中，则需要用ubiformat命令烧写，uboot命令行状态下，可以用nand write烧写
./ubiformat /dev/mtd8 -f ./HS-V6Pro-1024MB_minifs.bin -s 512 -O 2048

bootargs参数用例：
setenv bootargs ' console=ttyO0,115200n8,rootwait=1 ro ubi.mtd=4,2048 rootfstype=ubifs root=ubi0:rootfs init=/init mem=256M vram=20M notifyk.vpssm3_sva=0xBFD00000   cmemk.phys_start=0x90000000 cmemk.phys_end=0x96800000 cmemk.allowOverlap=1 earlyprintk';saveenv

ubifs文件系统，如果是没有使用ubiformat工具对mtd分区进行格式化，就需要使用mkfs.ubifs -F选项
==================================================









