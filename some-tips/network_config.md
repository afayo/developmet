1.在同一个网卡上配置多个ip地址

在一个卡上增加多个IP,其实是虚拟IP,但是它们公用一个网卡,如eth0是第一个网络卡,eth0:1 ,eth0:2等等是建立在eth0上的虚拟网络接口 ethx:n(n等于0-255),
ifconfig eth0 192.168.2.238 netmask 255.255.255.0  // eth0第一个网络接口
ifconfig eth0:1 192.168.2.238 netmask 255.255.255.0  //虚拟网络接口1
ifconfig eth0:2 192.168.2.238 netmask 255.255.255.0  //虚拟网络接口2
ifconfig eth0:3 192.168.2.238 netmask 255.255.255.0

参考文档:http://www.360doc.com/content/12/0223/00/7313939_188780792.shtml

2.PC机上,添加多个路由

语法
route [-f] [-p] [Command [Destination] [mask Netmask] [Gateway] [metric Metric]] [if Interface]]

route add default gw 192.168.1.1
route add 0.0.0.0 netmask 0.0.0.0 gw 192.168.1.119
route delete 0.0.0.0

route add  192.168.10.0 netmask 255.255.255.0 192.168.10.254
route delete  192.168.10.0

To add a default gateway address is 192.168.12.1 the default route, type:
route add 0.0.0.0 mask 0.0.0.0 192.168.12.1

Example To display the full contents of IP routing table, type:

route print

To display the IP routing table 10. Start routing, type:

route print 10 .*

To add a default gateway address is 192.168.12.1 the default route, type:

route add 0.0.0.0 mask 0.0.0.0 192.168.12.1

To add a goal to 10.41.0.0, the subnet mask of 255.255.0.0, the next hop address of 10.27.0.1, type:

route add 10.41.0.0 mask 255.255.0.0 10.27.0.1

To add a goal to 10.41.0.0, the subnet mask of 255.255.0.0, the next hop address of 10.27.0.1 permanent routing, type:

route-p add 10.41.0.0 mask 255.255.0.0 10.27.0.1

To add a goal to 10.41.0.0, the subnet mask of 255.255.0.0, the next hop address of 10.27.0.1, the routing metric of 7, type:

route add 10.41.0.0 mask 255.255.0.0 10.27.0.1 metric 7

To add a goal to 10.41.0.0, the subnet mask of 255.255.0.0, the next hop address of 10.27.0.1, the interface index for the 0x3 route, type:

route add 10.41.0.0 mask 255.255.0.0 10.27.0.1 if 0x3

To delete a target 10.41.0.0, subnet mask of 255.255.0.0, type:

route delete 10.41.0.0 mask 255.255.0.0

To delete IP routing table 10. Started all the routing, type:

route delete 10 .*

To target 10.41.0.0, subnet mask 255.255.0.0 route of the next hop address change by the 10.27.0.1 10.27.0.25, type:

route change 10.41.0.0 mask 255.255.0.0 10.27.0.25 


