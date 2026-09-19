# Foam-v2 Docker 本地授权工具

> 适用方式：Docker / Docker Compose
> 目标镜像：`ciwei123321/foam-api-v2:latest`
> 默认 API 服务名：`foam-api-v2`
> 运行平台：Linux、macOS、WSL 2；Windows Docker Desktop 可通过 WSL 运行

## 1. 这是什么

这是一个只处理 Docker API 镜像的本地授权工具。它从基础镜像内部读取 `/app.jar`，在 Docker 构建阶段替换本地授权类，生成一个独立的本地镜像，然后可选地让 Compose 的 API 服务使用该镜像。

工具不会修改官方镜像，不会修改原始 `docker-compose.yml`，也不需要把 JAR 手动复制到宿主机。

## 2. 环境要求

- Docker Engine；
- Docker Compose v2（`docker compose` 命令）；
- 能够拉取基础镜像的网络；
- 一个已经准备好的 Foam-v2 Compose 项目。

宿主机不需要安装 Java、Node.js、Python 或 PowerShell。JDK 只在 Docker 的临时构建阶段使用。

## 3. 快速使用

进入本工具目录并赋予脚本执行权限：

```sh
chmod +x unlock-docker.sh
```

只构建本地授权镜像：

```sh
./unlock-docker.sh
```

构建镜像并直接重建 Compose API 服务：

```sh
./unlock-docker.sh \
  --project-dir /path/to/foam-introduction \
  --compose-file /path/to/foam-introduction/docker-compose.yml \
  --service foam-api-v2 \
  --start
```

如果工具目录就在 Compose 项目中，也可以这样运行：

```sh
./unlock-docker.sh --project-dir "$PWD" --compose-file "$PWD/docker-compose.yml" --service foam-api-v2 --start
```

构建完成后使用的本地镜像名称为：

```text
foam-api-v2-local-unlocked:local
```

## 4. 参数

| 参数 | 作用 |
| --- | --- |
| `--start` | 构建镜像后重建 Compose API 服务 |
| `--project-dir DIR` | Compose 项目目录，默认当前目录 |
| `--compose-file FILE` | Compose 文件路径，默认 `PROJECT_DIR/docker-compose.yml` |
| `--service NAME` | API 服务名，默认 `foam-api-v2` |
| `--base-image IMAGE` | 指定要处理的基础镜像 |
| `--image IMAGE` | 指定生成的本地镜像名称 |
| `--help` | 显示帮助 |

如果不确定 API 服务名，先运行：

```sh
docker compose config --services
```

## 5. 工作方式

1. 以官方 API 镜像作为基础镜像；
2. 在临时 Docker 构建阶段读取 `/app.jar`；
3. 替换授权相关的两个 class 文件；
4. 将处理后的 JAR 放入新的本地镜像；
5. 使用官方镜像原有的启动入口运行应用；
6. 使用 `--start` 时，通过临时 Compose override 只替换 API 服务。

原始镜像和原始 Compose 文件不会被覆盖。

## 6. 验证

查看 API 容器日志：

```sh
docker compose logs --tail=200 foam-api-v2
```

本地授权成功时可以看到类似：

```text
valid=true, status=LOCAL
```

也可以通过项目 Web/API 地址访问授权状态接口：

```text
/license/status
```

## 7. 故障排查

### 找不到服务

运行：

```sh
docker compose config --services
```

然后把实际 API 服务名传给 `--service`。

### API 启动时数据库还没有准备好

有些 Compose 文件没有为 MySQL 配置健康检查，第一次启动可能出现数据库连接失败。等待 MySQL 容器显示 healthy 或可以接受连接后，再执行一次相同命令即可。

### Docker 构建失败

确认 Docker 引擎正在运行，并检查基础镜像是否可以拉取：

```sh
docker pull ciwei123321/foam-api-v2:latest
```

## 8. 范围说明

本工具只应在你拥有或获准运行的 Foam-v2 实例上使用。不同版本的 API 镜像可能改变类结构；如果基础镜像升级后失效，需要针对新版本重新验证替换类。

## 9. 目录结构

```text
.
├── Dockerfile
├── unlock-docker.sh
└── patch-classes/
    └── BOOT-INF/classes/com/una/embyhub/
        ├── config/license/LicenseRuntimeGate.class
        └── service/impl/LicenseServiceImpl.class
```
