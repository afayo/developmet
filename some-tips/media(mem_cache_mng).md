1.在基于海思hi3531的项目上,继续采用共享内存交互码流的测流,分为两个段,一个是mem段,负责实时接收编码器输出的数据,另一个是cache段,用于
为不同的应用服务同时提供同一路视频码流数据.但是在8月29日的那天,afa在修复暂停录制的问题的时候,不小心改变了mem和cache段的blk块的
大小,导致系统存取数据的效率低下,后果就是,录制卡顿,多流录制完全不能用,推流卡顿,sample_hison的CPU暂用率直线飙升,高达64%,这是极为不
正常的现象.经过几天的排查,最后发现,是由于afa同志将mem段和cache段的blk大小调整了,造成系统效率地下.为什么会这样呢?
经过进一步分析,发现由于mem段的blk块是采用循环覆盖利用的策略,单位blk大小可以根据具体P帧码流大小进行调整,保留一定的
冗余度即可,所以调整了mem的blk大小对于系统的效率并没有直接的影响.
那么问题的关键就在于afa同志调整了cache段的blk块的大小,而cache段使用blk块的策略是从头到尾,轮询每块blk,看看是否为空,如果是空,且连续的
N块都是空(N块是当前帧码流数据存储所需要的大小),那么就写入数据,否则就返回失败,问题说道这里,想必大家都差不多明白原因在哪里了吧,
由于afa将cache段的blk调小.也就是说同样大小的cache段,可以划分为更多的blk块数,当blk基数较大时,blk_num数是成倍增加的,也就是说,每次应用
服务获取每一帧的码流数据,需要多N倍的CPU频率,用于查询当前cache段上能够使用的blk块.

调整前的mem段和cache段配置:
MEM_LAYOUT mem_layout_setting[MEM_LAYOUT_NUM]= {

    [MEM_LAYOUT_1] = {
		              .profiles[VIDOE_INFO_CH1] = {
                                                   .cache_size =0x600000-(MP4_2_EXTRA_SIZE/2),
                                                   .cache_blk_size =(50 * 1024),
                                                   .mem_size =0x600000-(MP4_2_EXTRA_SIZE/2),
                                                   .mem_blk_size =(30 * 1024),
                                                   .ext_size = MP4_2_EXTRA_SIZE,
                                                   },
                      .profiles[VIDOE_INFO_CH2] = {
												   .cache_size =0x600000-(MP4_2_EXTRA_SIZE/2),
												   .cache_blk_size =(50 * 1024),
												   .mem_size =0x600000-(MP4_2_EXTRA_SIZE/2),
												   .mem_blk_size =(30 * 1024),
												   .ext_size =MP4_2_EXTRA_SIZE,
												   },                                                   
                      .profiles[VIDOE_INFO_CH3] = {
                                                    .cache_size =0x600000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(50 * 1024),
                                                    .mem_size =0x600000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(30 * 1024),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    },
                      .profiles[VIDOE_INFO_CH4] = {
                                                    .cache_size =0x800000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(50 * 1024),
                                                    .mem_size =0x800000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(40 * 1024),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    },
                      .profiles[VIDOE_INFO_CH5] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(10 * 1024),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(10 * 1024),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                     .profiles[VIDOE_INFO_CH6] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(10 * 1024),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(10 * 1024),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    },  
                      .profiles[VIDOE_INFO_CH7] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(10 * 1024),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(10 * 1024),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                      .profiles[VIDOE_INFO_CH8] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(10 * 1024),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(10 * 1024),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                      .profiles[VIDOE_INFO_CH9] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(10 * 1024),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(10 * 1024),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                     .profiles[VIDOE_INFO_CH10] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(10 * 1024),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(10 * 1024),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                       .profiles[VIDOE_INFO_CH11] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(10 * 1024),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(10 * 1024),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                                                                                                                                                                                                                                                                                      
                      .profiles[AUDIO_INFO_CH1] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(4*1024),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(512),
                                                    .ext_size = 0,
                                                    },
                      .profiles[AUDIO_INFO_CH2] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(4*1024),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(512),
                                                    .ext_size = 0,
                                                    },
                      .profiles[AUDIO_INFO_CH3] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(4*1024),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(512),
                                                    .ext_size = 0,
                                                    },
                      .profiles[AUDIO_INFO_CH4] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(4*1024),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(512),
                                                    .ext_size = 0,
                                                    },
                      .profiles[AUDIO_INFO_CH5] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(4*1024),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(512),
                                                    .ext_size = 0,
                                                    },
				   .profiles[AUDIO_INFO_CH6] = {
												.cache_size =0x100000,
												.cache_blk_size =(4*1024),
												.mem_size =0x100000,
												.mem_blk_size =(512),
												.ext_size = 0,
												},                                                                                                                                                                                                                                                                                                                                                                        
                      .totalsizes = 0,
                      }

};


优化调整后的mem段和cache段配置:(这里是将cache段上每个通过道的视频码流数据预留在120到180块的大,也就是3秒60帧的大小,而
                              音频数据配置为250帧左右的数据,对于44100的采样率,每帧音频数据大小是1024个点,那么就是6秒左右的音频数据)

MEM_LAYOUT mem_layout_setting[MEM_LAYOUT_NUM]= {

    [MEM_LAYOUT_1] = {
		              .profiles[VIDOE_INFO_CH1] = {
                                                   .cache_size =0x600000-(MP4_2_EXTRA_SIZE/2),
                                                   .cache_blk_size =(512),
                                                   .mem_size =0x600000-(MP4_2_EXTRA_SIZE/2),
                                                   .mem_blk_size =(512),
                                                   .ext_size = MP4_2_EXTRA_SIZE,
                                                   },
                      .profiles[VIDOE_INFO_CH2] = {
												   .cache_size =0x600000-(MP4_2_EXTRA_SIZE/2),
												   .cache_blk_size =(512),
												   .mem_size =0x600000-(MP4_2_EXTRA_SIZE/2),
												   .mem_blk_size =(512),
												   .ext_size =MP4_2_EXTRA_SIZE,
												   },                                                   
                      .profiles[VIDOE_INFO_CH3] = {
                                                    .cache_size =0x600000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(512),
                                                    .mem_size =0x600000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(512),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    },
                      .profiles[VIDOE_INFO_CH4] = {
                                                    .cache_size =0x800000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(512),
                                                    .mem_size =0x800000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(512),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    },
                      .profiles[VIDOE_INFO_CH5] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(512),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(512),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                     .profiles[VIDOE_INFO_CH6] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(512),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(512),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    },  
                      .profiles[VIDOE_INFO_CH7] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(512),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(512),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                      .profiles[VIDOE_INFO_CH8] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(512),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(512),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                      .profiles[VIDOE_INFO_CH9] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(512),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(512),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                     .profiles[VIDOE_INFO_CH10] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(512),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(512),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                       .profiles[VIDOE_INFO_CH11] = {
                                                    .cache_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .cache_blk_size =(512),
                                                    .mem_size =0x100000-(MP4_2_EXTRA_SIZE/2),
                                                    .mem_blk_size =(512),
                                                    .ext_size = MP4_2_EXTRA_SIZE,
                                                    }, 
                                                                                                                                                                                                                                                                                      
                      .profiles[AUDIO_INFO_CH1] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(128),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(128),
                                                    .ext_size = 0,
                                                    },
                      .profiles[AUDIO_INFO_CH2] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(128),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(128),
                                                    .ext_size = 0,
                                                    },
                      .profiles[AUDIO_INFO_CH3] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(128),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(128),
                                                    .ext_size = 0,
                                                    },
                      .profiles[AUDIO_INFO_CH4] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(128),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(128),
                                                    .ext_size = 0,
                                                    },
                      .profiles[AUDIO_INFO_CH5] = {
                                                    .cache_size =0x100000,
                                                    .cache_blk_size =(128),
                                                    .mem_size =0x100000,
                                                    .mem_blk_size =(128),
                                                    .ext_size = 0,
                                                    },
				   .profiles[AUDIO_INFO_CH6] = {
												.cache_size =0x100000,
												.cache_blk_size =(128),
												.mem_size =0x100000,
												.mem_blk_size =(128),
												.ext_size = 0,
												},                                                                                                                                                                                                                                                                                                                                                                        
                      .totalsizes = 0,
                      }

};

从上面看到的配置分析看,每个通道的blk块数应该是能够容纳该通道数据的(3-8秒视频数据)(音频则是5-8秒)为宜.
afa分析,还可以进一步优化cache段上取每个通道数据时,查询闲置的blk的策略方法,通过提高查询效率,提高整个系统
的数据吞吐效率,从而提高整个高清录播系统整体性能.

