# tcpdump_support_cmdline
这是一款基于linux lua写的增强版抓包工具， 支持过滤指定Android包名或应用启动时的cmdline
由于项目引用libpcap，以及tcpdump-master本身过大，所以只抽取修改到tcpdump.c 以及helper.lua文件，如果想用的朋友可以自己去github其他地方下载最新的tcpdump-master以及libpcap库。


用法:
  tcpdump -P com.titan.test （只对com.titan.test包名相关的进程进行抓包）
  或
  tcpdump -P firefox（只对火狐浏览器相关的进程进行抓包）
