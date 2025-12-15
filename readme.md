# VSCode Remote SSH 旧版 Linux 系统兼容工具

本仓库提供了一套脚本工具，用于解决在旧版 Linux 系统（glibc < 2.28）上使用 VSCode Remote SSH 的兼容性问题。

## 快速开始

### 一键安装（推荐）

使用 `setup_all.sh` 一键完成所有配置：

```bash
bash setup_all.sh
```

该脚本会自动完成以下操作：
1. 检测并安装 Miniconda3（如果未安装）
2. 创建 libc_env 环境并安装必要的依赖（sysroot_linux-64=2.28、patchelf）
3. 自动为 VSCode Server 应用补丁

---

## 分步安装

如果您需要单独执行某个步骤，可以使用以下脚本：

### 1. setup_anaconda.sh

#### 功能介绍
- 自动下载并安装 Miniconda3
- 在用户主目录下安装（`~/miniconda3`）
- 创建专用的 `libc_env` conda 环境
- 安装 `sysroot_linux-64=2.28` 和 `patchelf` 工具
- 自动配置环境变量

#### 使用方法
```bash
bash setup_anaconda.sh
```

---

### 2. setup_vscode_patch.sh

#### 功能介绍
- 使用 conda 环境中的 glibc 2.28 库文件
- 使用 patchelf 修改 VSCode Server 的 node 二进制文件
- 将 node 的动态链接器指向 conda 环境中的新版 glibc
- 立即执行一次补丁脚本，修复已安装的 VSCode Server
- 生成补丁脚本供后续使用（`~/.ssh/patch_all_code_servers.sh`）

#### 使用方法
```bash
bash setup_vscode_patch.sh
```

#### 重新应用补丁
如果后续 VSCode Server 更新，可以手动重新应用补丁：
```bash
bash ~/.ssh/patch_all_code_servers.sh
```

---

## VSCode 客户端配置

在本地 VSCode 中需要修改设置：

**取消勾选 `remote.ssh.useExecServer`**

设置路径：Settings → 搜索 "remote.ssh.use exec server" → 取消勾选

![](./images/local_vscode_setting.png)

---

## 验证补丁是否成功

使用以下命令检查 node 的动态链接：

```bash
ldd ~/.vscode-server/bin/<commit-id>/node
```

> 注意：将 `<commit-id>` 替换为实际的 VSCode Server 版本号

如果看到 glibc 路径指向 `~/miniconda3/envs/libc_env/...`，则说明补丁应用成功。

![](./images/ldd_node.jpg)

---

## 注意事项

- 脚本会自动处理 SSL 证书验证问题（如果遇到）
- 如果 VSCode 连接仍有问题，尝试更新 Remote-SSH 扩展到最新版本
- 补丁脚本会保存在 `~/.ssh/patch_all_code_servers.sh`，可随时手动执行

---

## 脚本说明

| 脚本名称 | 功能 | 是否必需 |
|---------|------|---------|
| `setup_all.sh` | 一键完成所有配置 | 推荐使用 |
| `setup_anaconda.sh` | 安装 Miniconda 和配置环境 | 必需（可单独执行） |
| `setup_vscode_patch.sh` | 应用 VSCode Server 补丁 | 必需（可单独执行） |
