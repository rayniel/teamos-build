# 构建操作手册

## 1. 文档目标

本文档用于说明 `teamos-build` 仓库中团队定制 ISO 的标准构建流程，覆盖：

- 构建机准备
- 依赖安装
- 仓库目录职责
- `live-build` 初始化与执行
- 软件包清单与品牌资源注入方式
- 构建产物验证
- 常见问题排查

本文档面向内部维护者，目标是让新的维护者能够在一台干净的 Debian 构建机上重复构建出相同的 ISO。

---

## 2. 适用范围

本手册适用于方案 A：

- 以 Debian stable 为底
- 使用 `live-build` 生成 ISO
- 按需参考或引入 BunsenLabs 组件
- 使用团队自己的 branding、默认配置与软件包集合

不适用于：

- 直接 remaster 官方 BunsenLabs ISO
- 构建对外发行版级别多架构镜像
- 深度定制安装器内部模块

---

## 3. 构建环境要求

### 3.1 推荐操作系统

建议使用：

- Debian stable

理论上 Ubuntu 也可能可用，但首选 Debian 以减少兼容偏差。

### 3.2 硬件建议

最低建议：

- 4 vCPU
- 8 GB RAM
- 40 GB 可用磁盘空间

推荐配置：

- 8 vCPU
- 16 GB RAM
- 80 GB 可用磁盘空间

### 3.3 网络要求

构建阶段需要访问：

- Debian 软件源
- 如启用，BunsenLabs 软件源
- 团队内部资源地址（如证书、脚本、文档资源）

---

## 4. 构建机依赖安装

在 Debian 构建机上安装基础工具：

```bash
sudo apt update
sudo apt install -y \
  live-build \
  debootstrap \
  squashfs-tools \
  xorriso \
  isolinux \
  syslinux-common \
  grub-pc-bin \
  grub-efi-amd64-bin \
  mtools \
  dosfstools \
  git \
  rsync \
  curl \
  wget \
  gnupg \
  ca-certificates \
  jq \
  qemu-system-x86 \
  qemu-utils
```

如后续需要本地测试 UEFI/BIOS 启动，建议额外安装：

```bash
sudo apt install -y ovmf
```

---

## 5. 仓库目录说明

当前项目建议目录结构如下：

```text
teamos-build/
├── build.sh
├── config/
│   ├── package-lists/
│   ├── archives/
│   ├── includes.chroot/
│   ├── includes.binary/
│   ├── hooks/
│   └── bootloaders/
├── branding/
└── docs/
```

各目录职责：

- `build.sh`：统一构建入口
- `config/package-lists/`：软件包分层清单
- `config/archives/`：APT 源配置
- `config/includes.chroot/`：注入到目标根文件系统中的文件
- `config/includes.binary/`：注入到 ISO binary 层的文件
- `config/hooks/`：构建阶段执行的钩子脚本
- `branding/`：Logo、壁纸、GRUB、Plymouth、Calamares 资源
- `docs/`：设计与运维文档

---

## 6. 初始化流程

### 6.1 获取源码

```bash
git clone https://github.com/rayniel/teamos-build.git
cd teamos-build
```

### 6.2 清理旧构建环境

每次重新构建前建议先执行：

```bash
sudo lb clean --purge || true
```

这可以避免上一次构建遗留的缓存影响结果。

---

## 7. 软件包清单管理

软件包按分层方式维护：

```text
config/package-lists/
├── base.list.chroot
├── desktop.list.chroot
├── bunsen.list.chroot
└── team.list.chroot
```

说明：

- `base.list.chroot`：最小系统基础与联网能力
- `desktop.list.chroot`：Openbox 图形桌面与基础应用
- `bunsen.list.chroot`：选择性引入的 BunsenLabs 组件
- `team.list.chroot`：团队工作软件

建议原则：

- 首版尽量少而稳
- `bunsen.list.chroot` 保持极简
- 新增包必须说明用途与依赖风险

---

## 8. 软件源管理

### 8.1 Debian 源

默认使用 Debian stable 官方源。

### 8.2 BunsenLabs 源

如需引入 BunsenLabs 包，可在：

```text
config/archives/
```

中添加额外源定义与 keyring 处理逻辑。

建议规则：

- 仅在确认需要某个 BunsenLabs 包时再启用
- 使用白名单方式安装，不做全量依赖
- 引入前先记录来源仓库、用途和替代方案

### 8.3 第三方源

原则上第一版不建议增加大量第三方源。

如必须增加：

- 必须记录 GPG key 管理方式
- 必须写明用途与风险
- 不允许使用不可审计的临时安装脚本

---

## 9. Branding 与文件覆盖

### 9.1 根文件系统覆盖

以下内容应放入：

```text
config/includes.chroot/
```

常见示例：

- `/etc/os-release`
- `/etc/issue`
- `/etc/issue.net`
- `/etc/skel/`
- `/usr/share/backgrounds/`
- `/usr/share/icons/`
- `/usr/local/bin/`

### 9.2 ISO binary 层覆盖

以下内容可放入：

```text
config/includes.binary/
```

常见示例：

- 启动菜单背景资源
- ISO 顶层 README
- 额外分发说明文件

### 9.3 品牌资源管理

建议所有原始品牌资源先放在：

```text
branding/
```

然后通过脚本或 includes 目录统一注入到构建产物中。

---

## 10. 默认配置管理

### 10.1 `/etc/skel`

用户默认配置统一放在：

```text
config/includes.chroot/etc/skel/
```

建议包含：

- `~/.config/openbox/`
- `~/.config/tint2/`
- `~/.config/gtk-*`
- 浏览器书签或欢迎页入口
- 团队快捷方式

### 10.2 脚本与工具

团队脚本建议放在：

```text
config/includes.chroot/usr/local/bin/
```

例如：

- 首次启动脚本
- 团队文档入口脚本
- 环境初始化脚本

---

## 11. BunsenLabs 参考组件策略

结合 BunsenLabs 组织中的公开仓库，当前优先参考：

- `bunsen-configs`
- `bunsen-configs-live`
- `bunsen-welcome`
- `bunsen-os-release`
- `bunsen-themes`
- `bunsen-images`
- `bunsen-common`

建议做法：

1. 优先学习其目录结构和配置方式
2. 优先复制“思路”而不是整包照搬
3. 仅在确有必要时添加具体 `bunsen-*` 包
4. 团队品牌、文案与入口全部由本项目维护

主题与图标策略（当前实现）：

1. 不添加 BunsenLabs 第三方 APT 源，仅使用 Debian 默认源
2. 从 GitHub 拉取 `bunsen-themes` 仓库并复制到 `/usr/share/themes/`
3. 图标主题保持发行版默认值（不依赖 BunsenLabs 包名）
4. 额外从 GitHub 拉取 `archcraft-openbox-themes`，将 `OB-*` 主题复制到 `/usr/share/themes/`（可通过环境变量 `TEAMOS_INSTALL_ARCHCRAFT_THEMES=0` 关闭）

对应脚本：

- `config/hooks/normal/0050-bunsenlabs-themes.hook.chroot`

---

## 12. 构建执行

### 12.1 最小构建流程

在仓库根目录执行：

```bash
./build.sh
```

清理工作目录（保留共享缓存和产物）：

```bash
./build.sh clean
```

严格清理（工作目录、产物、缓存全部清空）：

```bash
./build.sh clean-all
```

如未准备好 `build.sh`，也可以手工执行：

```bash
sudo lb clean || true
lb config
sudo lb build
```

### 12.2 构建产物

当前 `build.sh` 会把构建过程与产物统一放在项目内的 `out/` 目录：

- `out/work/`：`live-build` 工作目录（`binary/`、`chroot/`、缓存等）
- `out/artifacts/`：整理后的最终产物（如 `*.iso`、`live-image-*`、`build.log`）
- `out/cache/`：持久化下载缓存（用于减少重复下载）

说明：

- `out/` 已加入 Git 忽略，不会污染源码提交
- 默认构建会复用缓存，避免每次重下依赖
- `out/work/cache` 会自动链接到 `out/cache`，无需搬运缓存目录
- 直接执行 `./build.sh` 即可自动同步 `config/` 到工作目录并构建

构建完成后应记录：

- Git commit SHA
- 构建时间
- Debian 基线版本
- 关键缓存策略（是否复用 `out/cache/`）

---

## 13. 本地测试流程

### 13.1 QEMU 快速测试

示例：

```bash
qemu-system-x86_64 \
  -m 4096 \
  -smp 4 \
  -enable-kvm \
  -cdrom ./live-image-amd64.hybrid.iso \
  -boot d
```

如需测试安装流程，可添加虚拟磁盘：

```bash
qemu-img create -f qcow2 testdisk.qcow2 40G

qemu-system-x86_64 \
  -m 4096 \
  -smp 4 \
  -enable-kvm \
  -cdrom ./live-image-amd64.hybrid.iso \
  -drive file=testdisk.qcow2,format=qcow2 \
  -boot d
```

### 13.2 必测项

Live 模式：

- 能正常启动
- 能进入桌面
- 网络可用
- 文件管理器和终端可用
- 浏览器可用
- 中文字体显示正常
- 团队壁纸、Logo、生效文案正确

安装模式：

- 安装器可启动
- 安装流程可完成
- 重启后可进入系统
- 默认用户配置已生效

---

## 14. 发布前检查

每次内部发布前，至少检查：

- [ ] ISO 可启动
- [ ] Live 桌面可进入
- [ ] 网络正常
- [ ] 品牌替换完整
- [ ] 无明显 BunsenLabs 品牌残留
- [ ] 默认软件可用
- [ ] 团队文档入口可访问
- [ ] 安装器可运行（如该版本包含）
- [ ] 安装后系统可启动

建议同时参考：

- `docs/branding-checklist.md`
- `docs/package-plan.md`

---

## 15. 常见问题

### 15.1 构建中断或依赖下载失败

处理建议：

- 检查网络与 APT 源
- 清理构建缓存后重试
- 检查第三方源 key 是否过期

### 15.2 ISO 能启动但桌面不完整

处理建议：

- 检查 `desktop.list.chroot`
- 检查 `includes.chroot/etc/skel`
- 检查 Openbox 和 LightDM 相关配置覆盖

### 15.3 品牌残留

处理建议：

- 使用 `grep -RniE` 对 includes 与 branding 目录扫描
- 专项检查 `.desktop`、Openbox 菜单、欢迎页和安装器文案

### 15.4 某些 BunsenLabs 组件依赖复杂

处理建议：

- 优先复制配置思路
- 如整包引入导致依赖过重，改为自维护配置

---

## 16. 维护建议

建议维护团队遵守以下规则：

- 所有构建改动必须提交到 Git
- 不在构建过程中手工修改 chroot
- 每新增一个软件包，都记录用途
- 每新增一��品牌资源，都记录对应替换位置
- 每次发布都保留版本说明和变更记录

---

## 17. 后续工作

在本手册基础上，下一步应完成：

1. 创建 `config/package-lists/` 初版文件
2. 创建 `build.sh`
3. 创建 `config/includes.chroot/` 基础目录
4. 补齐 `/etc/os-release` 与 `/etc/skel` 初版模板
5. 按优先级分析 BunsenLabs 参考仓库中的可复用内容

---

## 18. 结论

本项目的目标不是复制一个完整上游发行版，而是建立一个：

- 以 Debian stable 为底
- 吸收 BunsenLabs 轻量桌面经验
- 由团队自己掌控构建与品牌
- 可重复交付的内部使用 ISO

只要坚持：

- 脚本化构建
- 分层包管理
- 品牌统一替换
- 先小后大迭代

这个项目就可以稳定推进到可用状态。
