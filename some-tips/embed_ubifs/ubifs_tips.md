
    最近在处理嵌入式系统升级和程序固件如何长时间保证不损坏，发现升级和系统固件的存储需要有个策略，主要分为两步，一个应用程序打包和文件系统的可读写挂载，
为了让程序固件长时间不损坏，建议采用文件系统只读和应用程序固件只读，对于应用中需要用到可读写目录，可以统一分配一个固定的nand分区，在同一个可读写的分区上
进行读写。同时，为了升级的简便性和可靠性，最好采用一个最小文件系统来作为升级系统的根文件系统，这样可以可靠的保证升级原来的根文件系统、内核、应用等等。

在使用ubifs文件系统的过程中，需要了解ubifs文件系统相关知识，这些可以参考《ubifs文件系统.zip 》，下面主要讲述，在这个过程中主要遇到的问题，

首先是：mkfs.ubifs命令，该命令属于mtd-utils工具
如下：
mkfs.ubifs -r </path/to/your/rootfs/tree> -m <min io size>
  -e <LEB size> -c <Eraseblocks count>
  -o </path/to/output/ubifs.img>
  
mkfs.ubifs -r minifs -F -o ./minifs.img -m 2048 -e 126976 -c 90
-r :表示需要生成固件的目录
-F :表示自动填充剩下的空间，对应uboot命令烧写根文件系统，如：nand write 写入的固件，在生成的时候，一定要添加上-F选项
-o ：表示要输出的固件名
-m ：nandflash的页大小，2048字节
-e ：ubifs 的 LEB块，UBI is a “volume manager” and maps physical  erase blocks (PEB) to logical erase blocks (LEB). 
The LEBs are smaller than the  PEBs because of meta-data and headers.他们的关系是：
