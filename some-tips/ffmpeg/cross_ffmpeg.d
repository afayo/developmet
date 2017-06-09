在交叉编译ffmpeg的时候，需要注意配置参数，对应DM8148,没有裁剪的配置如下：

PKG_CONFIG_PATH="./../lib/pkgconfig" ./configure --arch=arm \
    --cpu=cortex-a8 \
	--target-os=linux \
   	--enable-cross-compile \
	--cross-prefix=arm-arago-linux-gnueabi- \
   	--extra-cflags='-march=armv7-a -mfpu=neon -marm -mfloat-abi=softfp -mtune=cortex-a8 -I./../include'  \
	--extra-ldflags="-L./../lib" \
	--prefix=./..
	
	
	
	如果需要裁剪，用户根据./configure --help 查看帮助文档
注意：1.如果提示不能创建可执行程序,则需要将交叉编译工具添加在系统环境变量PATH中,然后export PATH,当前shell下既可以生效.

2,如果提示如下信息,表示,由于编译其指定了编译选项-Werror,但出现变量已经不再使用,在程序代码中却又用到了destruct,所以会报错,
解决办法是去除编译选项-Werror
error: 'destruct' is deprecated (declared at /media/hison/home/afa/work/dm8148/Source/ipnc_rdk/../ipnc_rdk/ipnc_app/lib3rd/ffmpeg_2_5_2/include/libavcodec/avcodec.h:1444)

	

