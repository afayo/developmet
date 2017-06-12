
实用的github使用技巧：
http://www.cnblogs.com/aGboke/p/6530369.html
http://blog.csdn.net/u010800530/article/details/41207431
https://developer.github.com/webhooks/
https://github.com/explore

============================================================

基本命令：
cd d:\github  
git init   
//user.name是你自己的github的名字  
git config user.name "penglongli"    
//user.email是你注册的时候的邮箱  
git config user.email "1589987691@qq.com"   
//添加文件  
git add helloworld.txt  
//git commit -m 参数后面跟字符串，告诉Git本次修改的说明信息。总是应该在每次提交的时候注明说明信息。  
git commit -m "first commit"   
//这里输入远程地址 ,即配置远端的代码库服务器地址的别名，方便后面使用。 
git remote add origin https://github.com/penglongli/FirstRepository.git  
//这里输入名字和密码  
git push origin master  

// 生成本地代码库  
git clone  https://github.com/afayo/developmet.git


//查看本地缓存中的修改状态
git status

比较文件
git diff readme.txt 

查看日志
git log

git log --pretty=oneline


首先，Git必须知道当前版本是哪个版本，在Git中，用HEAD表示当前版本，也就是最新的提交3628164...882e1e0（注意我的提交ID和你的肯定不一样），上一个版本就是HEAD^，上上一个版本就是HEAD^^，当然往上100个版本写100个^比较容易数不过来，所以写成HEAD~100。
git reset --hard HEAD^

找到需要恢复版本对应的commit id是3628164...，于是就可以指定回到未来的某个版本，可以只输入commit id的前几位即可。
git reset --hard 3628164

Git提供了一个命令git reflog用来记录你的每一次命令
git reflog

//git + tab键看到对应命立功
git xxx --help //查看具体命令的帮助 

============================================================
