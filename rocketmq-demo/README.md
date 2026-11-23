# rocketmq-demo

最小可运行的 RocketMQ 收发案例：启动后自动发一条消息，消费者收到后打印到控制台。

## 先回答一个关键问题

RocketMQ 不是 Java 代码里的库，而是一个**独立的服务**：

- `rocketmq-spring-boot-starter` 只是客户端，负责连服务、发消息、收消息；
- 真正存消息的是 NameServer（9876）和 Broker（10911），必须先下载并启动它们。

所以顺序永远是：先启动 RocketMQ 服务，再启动 Spring Boot 应用。

## 前置条件

| 项目 | 要求 |
| --- | --- |
| JDK | 17 及以上（本机 JDK 25 可运行，启动时有 Unsafe 警告，可忽略） |
| RocketMQ | 已解压到 `D:\devApplication\rocketmq\rocketmq-all-5.3.2-bin-release` |
| 端口 | 9876（NameServer）、10911（Broker）、8089（本应用） |
| 数据目录 | `D:\devApplication\rocketmq\store`（消息落盘位置，删掉等于清空所有消息） |
| 日志目录 | `D:\devApplication\rocketmq\logs`（启动输出与 RocketMQ 自身日志） |

RocketMQ 下载地址（国内可用镜像）：
`https://mirrors.aliyun.com/apache/rocketmq/5.3.2/rocketmq-all-5.3.2-bin-release.zip`

如果不是解压到上面的路径，修改 `rocketmq\start-rocketmq.ps1` 第一行的 `$RocketMqHome`。

## 启动步骤

在 `rocketmq-demo` 目录下打开两个终端。

终端一：启动 RocketMQ（NameServer + Broker + 预建 Topic）

```powershell
powershell -ExecutionPolicy Bypass -File .\rocketmq\start-rocketmq.ps1
```

终端二：启动应用

```powershell
mvn spring-boot:run
```

应用启动后控制台会出现两条日志：

```text
[发送成功] status=SEND_OK, msgId=..., body=应用启动后的第一条消息 | 12:36:45
[消费成功] 收到消息: 应用启动后的第一条消息 | 12:36:45
```

再发一条消息：

```powershell
curl "http://127.0.0.1:8089/send?msg=hello"
```

## 停止

```powershell
powershell -ExecutionPolicy Bypass -File .\rocketmq\stop-rocketmq.ps1
```

## 代码在哪

| 文件 | 作用 |
| --- | --- |
| `DemoProducer.java` | 用 `RocketMQTemplate.syncSend` 发消息，启动后自动发一条 |
| `DemoConsumer.java` | `@RocketMQMessageListener` 监听 `demo-topic`，收到后打印 |
| `DemoController.java` | `GET /send?msg=xxx` 手动发消息 |
| `application.yml` | NameServer 地址、生产者组 |
| `rocketmq\broker.conf` | Broker 配置（自动建 Topic、存储路径） |

## 常见问题

| 现象 | 原因 | 处理 |
| --- | --- | --- |
| 启动报 `connect to namesrv failed` | RocketMQ 没启动 | 先运行 `start-rocketmq.ps1` |
| 启动报内存不足 | 用了 RocketMQ 默认 8G 堆 | 启动脚本已通过 `JAVA_OPT_EXT` 改为 512M/1G |
| 发送成功但迟迟收不到 | Topic 首次创建后消费者要等路由刷新 | 启动脚本已预建 `demo-topic`，正常 1 秒内收到 |
| 10911 端口被占用 | 已有 Broker 在跑 | 脚本检测到端口占用会跳过启动 |
