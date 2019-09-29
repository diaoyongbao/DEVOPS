# Dockerfile使用详解
* `FROM`   用于拉取基础镜像，第一个非注释行
* `COPY`   用于从docker主机复制文件至创建的新映像文件
    *   `COPY <src>...<dest>`
    *  ` COPY ["src",..."<dest>"]`
    *   src要复制的源路径或目录，支持使用通配符，必须是build上下文中的路径，不能是其父目录
    *   dest目标路径，即正在创建的image的文件系统路径，建议使用绝对路径，否则，COPY指定则以WORKDIR为其起始目录
    *   如果src是目录，则其内部文件或子目录会被递归复制，而src目录则不会被复制
    *   如果指定了多个src或src中使用了通配符，dest必须是一个目录，且以/结尾
    *   如果dest事先不存在，则会被创建，包括其父目录
* `ADD` 类似于COPY指令，ADD支持使用tar文件和url路径
    *   `ADD <src>...<dest>`
    *   `ADD ["<src>,...<dest>"]`
    *   如果src为url且dest不以/结尾，则src指定的文件将被下载并直接创建为dest，如果dest以/结尾，则文件名url下载的文件将被保存为dest/filename
*  `WORKDIR` 配置工作目录
* `VOLUME` 定义匿名卷,事先指定某些目录挂载为匿名卷，运行时用户未指定挂载，应用也可正常运行，且不会向容器存储层写入大量数据
    *   `VOLUME <path>`
    *   `VOLUME["<path1>...<path2>"]`
* `EXPOSE` 用于为容器打开指定要监听的端口以实现与外部通信
    *   `EXPOSE <port>[/<protocol>] [<port>[/<protocol>]]`
*  `ENV` 用于为镜像定义所需的环境变量，并可被Dockerfile文件其后的指令所调用
    *   调用格式$var_name或${var_name}
    * `ENV key value` 此种格式，key之后的内容均会被视作value的组成部分，因此一次只能设置一个变量
    *  `ENV key=value` 可一次设置多个变量，每个变量都是一个“key=value”形式的键值对，如果value中包含空格可使用/进行转义
*  `RUN` 用于指定docker build过程中运行的程序，其可以是任何命令
    *   `RUN  <COMMAND>`
    *   `RUN ["<execute>","<param1>","<param2>"]`
    *   第一个命令中cmmand通常是一个shell命令，且以“/bin/sh -c”来运行它，意味着此进程在容器中的pid不为1，不能接受unix信号
    *   第二个命令的execute为要运行的命令，paramN为传递给它的参数 
* `CMD` 类似于RUN命令，CMD命令可用于任何命令或应用程序，不过二者的运行时间点不同
    *   `CMD <COMMAND>` 同RUN命令
    *   `CMD ["<execute>","<param1>","<param2>"]` 同RUN命令
    *   `CMD ["<param1>","<param2>"]` 用于为ENTRYPOINT命令提供默认参数
* `ENTRYPOINT` 于CMD功能类似，用于为容器指定默认运行程序，使容器像一个单独的可执行程序
    *   `ENTRYPOINT  <COMMAND>`
    *  `ENTRYPOINT ["<execute>","<param1>","<param2>"]`
    *   由ENTRYPOINT启动的程序不会被docker run 命令行指定的参数所覆盖，而且，这些命令行参数会被当做参数传递给ENTRYPOINT指定的程序，可使用docker run 命令的--entrypoint选项的参数可覆盖ENTRYPOINT指令指定的程序
    *  docker run命令传入的命令参数会覆盖CMD指令的内容并且附加到ENTRYPOINT命令最后做为其参数使用
* `HEALTHCHECK`
    *  `HEALTHCHECK [options] CMD [command]`
    *   --interval=<间隔> ：两次健康检查的间隔，默认为30秒
    *   --timeout=<时长> ：健康检查命令运行超时时间，如果超过这个时间，本次健康检查就被视为失败，默认30秒
    *   --retries=<次数> ：当连续失败指定次数后，则将容器状态视为 unhealthy ，默认3次
* `ARG` 定义变量在build时应用使用--build-arg <varname>=<value>，参数变量必须在dockerfile中定义
    *   `ARG <varname>[=<value>]`

# Dcokerfile示例
## Dockerfile
```
FROM nginx:1.14-alpine
LABEL maintainer="dyb<dyb0204@gmail.com>"
ENV NGX_DOC_ROOT='/data/web/html/'
ADD index.html ${NGX_DOC_ROOT}
ADD entrypoint.sh /bin/
EXPOSE 80/tcp
HEALTHCHECK --start-period=5s CMD wget -O - -q http://{IP:-0.0.0.0}
CMD ["/usr/sbin/nginx","-g","daemon off;"]
ENTRYPOINT [ "/bin/entrypoint.sh" ]
```
## entrypoint.sh
```
#!/bin/sh
#
cat > /etc/nginx/conf.d/default.conf << EOF
server {
        server_name 0.0.0.0;
        listen ${IP:-0.0.0.0}:${PORT:-80};
        root ${NGX_DOC_ROOT:-/usr/share/nginx/html};
}
EOF
# 修改nginx的默认配置文件
# 调用CMD中的命令替换此进程
exec "$@"
```
```
# index.html
<P>Docker Nginx Test Sever</P>
```
## 使用
```
docker build -t <image_name>:<tag> ./
docker run -it -d -p 80:80 <image_name>:<tag>
```