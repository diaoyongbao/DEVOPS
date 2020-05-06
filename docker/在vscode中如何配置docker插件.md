在vscode 的插件列表中进行docker的插件下载
本机安装docker，此处使用的是linux的arch，包管理工具为pacman，使用此进行下载
将一些参数修改到docker的启动中，修改systemd 的启动脚本即可，默认位置在/lib/systemd/system/docker.service
 -H tcp://0.0.0.0:2376  -H unix:///var/run/docker.sock
systemctl daemon-reload
systemctl restart docker
在vscode的设置中将
docker host修改为127.0.0.1 2376


TODO
在arch linux中测试不成功，待测试



