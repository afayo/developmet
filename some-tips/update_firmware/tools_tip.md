
首先强调，这里是在flash驱动移植好的前提下进行的，这里不涉及flash驱动移植，相关具体flash驱动移植，请自行查找资料解决。
嵌入式是升级文件系统中需要的工具有fw_printenv(uboot源码中自带，注意修改fw_env.h中变量，改成不依赖/etc/fw_env.config文件)，sync（busybox自带命令，用于及时将数据从系统缓存中刷到flash分区上去），
cat /proc/mdt;  mtdinfo /dex/mtdxxx; 此命令用于获取对应flash分区的信息，注意：默认情况下烧写uboot后，第一次启动，uboot环境变量是没有写进flash的，
这就需要借助fw_printenv工具，让其自带和uboot一样的默认参数，通过先运行，fw_printenv工具，将默认参数写入。

1.嵌入式升级系统中可以考虑裁剪一个最小文件系统（小于10M）的minifs，用于升级包括uboot在内的所有flash分区，
  注意：最小文件系统可以通过裁剪busybox来实现，具体操作可以借鉴网上的资料。
