# 团队定制 ISO 软件包规划

## 1. 文档目标

本文档用于定义团队定制 ISO 的软件包分层策略，作为后续 `live-build` 配置、软件源管理、构建测试和版本维护的依据。

目标是做到：

- 软件包职责清晰
- 依赖关系尽量简单
- 团队功能优先
- 对 BunsenLabs 保持选择性复用
- 便于后续维护和升级

---

## 2. 分层原则

软件包按职责拆分为以下四层：

1. `base`：最小系统运行基础
2. `desktop`：桌面体验层
3. `bunsen`：BunsenLabs 风格与辅助组件层
4. `team`：团队业务与工具层

每层使用独立的 `*.list.chroot` 文件管理，避免把所有内容堆进一个包清单中。

---

## 3. base 层

### 3.1 目标

`base` 层提供一个稳定、可联网、可管理、可调试的最小 Debian 运行环境。

### 3.2 建议软件包

```text
systemd-sysv
systemd-timesyncd
sudo
bash-completion
less
curl
wget
ca-certificates
gnupg
apt-transport-https
lsb-release
locales
tzdata
nano
vim-tiny
rsync
file
pciutils
usbutils
lsof
psmisc
procps
iproute2
iputils-ping
net-tools
dnsutils
openssh-client
openssh-server
network-manager
network-manager-gnome
wpasupplicant
wireless-tools
bluez
bluez-tools
avahi-daemon
```

### 3.3 说明

- `systemd-sysv`：确保系统使用 systemd 启动链
- `network-manager`：统一网络管理方式
- `openssh-server`：便于内部远程维护；如不需要可后续下调
- `gnupg` / `ca-certificates`：为后续添加仓库 key 和 HTTPS 软件源提供支持

---

## 4. desktop 层

### 4.1 目标

`desktop` 层提供一个轻量、稳定、适合内部办公/开发使用的图形桌面。

### 4.2 窗口与显示基础

```text
xorg
xinit
xserver-xorg
xserver-xorg-core
xserver-xorg-input-libinput
xserver-xorg-video-all
lightdm
lightdm-gtk-greeter
policykit-1
```

### 4.3 Openbox 与面板

```text
openbox
obconf
obmenu
menu
menu-xdg
tint2
nitrogen
picom
lxappearance
rofi
dunst
```

### 4.4 文件与终端工具

```text
thunar
thunar-archive-plugin
thunar-volman
gvfs
gvfs-backends
xfce4-terminal
file-roller
p7zip-full
unzip
zip
```

### 4.5 浏览器与基础图形工具

```text
firefox-esr
eog
ristretto
mousepad
galculator
pavucontrol
pulseaudio
alsa-utils
```

### 4.6 输入法与字体（如面向中文团队）

```text
fonts-noto-cjk
fonts-wqy-zenhei
fcitx5
fcitx5-chinese-addons
fcitx5-frontend-gtk3
fcitx5-frontend-gtk4
fcitx5-frontend-qt5
fcitx5-configtool
```

### 4.7 说明

- 以 Openbox 为核心，保持轻量
- 文件管理器优先选 `thunar`，生态稳定、依赖适中
- 终端默认 `xfce4-terminal`
- 中文环境如为刚需，建议第一版就纳入字体与输入法

---

## 5. bunsen 层

### 5.1 目标

`bunsen` 层只负责“继承有价值的 BunsenLabs 风格与工具”，不追求全量复刻。

### 5.2 引入策略

采用白名单原则：

- 仅引入明确需要的包
- 仅引入可以提升 Openbox 使用体验的组件
- 不因为“看起来像官方”而全量拉取

### 5.3 计划引入的内容类型

```text
# 待确认的 BunsenLabs 组件示例分类：
# - 主题/图标
# - Openbox 默认配置模板
# - 桌面会话辅助脚本
# - 菜单生成/欢迎工具
```

### 5.4 使用原则

在真正引入具体 BunsenLabs 包前，先完成：

1. 识别对应仓库/包名
2. 检查依赖
3. 判断是否可由自定义 overlay 直接替代
4. 若仅为少量配置文件，则优先复制思路而不是引入整包

### 5.5 风险控制

如某个 BunsenLabs 包：

- 依赖过多
- 品牌耦合严重
- 配置结构复杂
- 更新频率不可控

则优先改为：

- 自维护配置副本
- 自维护脚本
- 自维护主题资源

---

## 6. team 层

### 6.1 目标

`team` 层负责团队日常工作的工具栈，是 ISO 的实际业务价值层。

### 6.2 通用开发工具建议

```text
git
git-lfs
build-essential
make
cmake
pkg-config
jq
yq
tree
htop
btop
ripgrep
fd-find
silversearcher-ag
neovim
tmux
screen
```

### 6.3 容器与虚拟化工具（按需）

```text
docker.io
docker-compose
podman
qemu-system-x86
qemu-utils
virt-manager
```

> 注：以上不建议第一版全装，应按团队实际使用情况裁剪。

### 6.4 语言运行时（按需）

```text
python3
python3-pip
python3-venv
nodejs
npm
golang
openjdk-17-jdk
```

### 6.5 办公与协作类（按需）

```text
libreoffice
remmina
flameshot
obs-studio
```

### 6.6 网络与团队接入（按需）

```text
openvpn
wireguard
network-manager-openvpn
network-manager-openvpn-gnome
network-manager-vpnc
```

### 6.7 说明

`team` 层要尽量贴近实际使用场景，而不是追求“大而全”。

建议按以下方式拆分：

- `team-common`：所有成员都需要
- `team-dev`：开发人员需要
- `team-ops`：运维/基础设施需要
- `team-media`：设计/录屏/演示需要

在 live-build 初期，可先合并到一个 `team.list.chroot`，后续再拆。

---

## 7. 不建议第一版纳入的内容

以下内容建议暂缓：

```text
nvidia-driver
virtualbox-dkms
大型 IDE（如 jetbrains 全家桶）
完整 KDE/GNOME 桌面环境
自建内核
大量第三方闭源客户端
```

原因：

- 依赖重
- 镜像体积膨胀明显
- 驱动兼容复杂
- 增加首版集成风险

---

## 8. 软件源策略

### 8.1 Debian 源

以 Debian stable 为主。

### 8.2 BunsenLabs 源

仅用于获取经过筛选的 BunsenLabs 组件。

### 8.3 第三方源

第一版原则：

- 非必要不添加
- 如必须添加，必须说明用途、密钥管理方式和更新风险

### 8.4 原则

- 所有外部源都要可审计
- 所有 keyring 都应纳入构建过程管理
- 尽量避免安装阶段临时 curl | bash

---

## 9. 软件包清单文件规划

建议对应如下文件：

```text
config/package-lists/
├── base.list.chroot
├── desktop.list.chroot
├── bunsen.list.chroot
└── team.list.chroot
```

推荐职责：

- `base.list.chroot`：最小系统与网络能力
- `desktop.list.chroot`：图形环境与桌面工具
- `bunsen.list.chroot`：BunsenLabs 相关增强组件
- `team.list.chroot`：团队工作负载软件

---

## 10. 初版建议组合

### 10.1 最小可用组合

第一版建议优先完成：

- `base`
- `desktop`
- 极少量 `bunsen`
- 基础 `team`

### 10.2 建议首版范围

```text
base:
- 全量启用

desktop:
- 启用 Openbox、Thunar、终端、浏览器、字体、音频基础

bunsen:
- 只引入真正必要的主题/脚本/配置参考

team:
- git
- neovim
- tmux
- python3
- curl/jq 等基础工具
- VPN（若内部需要）
```

---

## 11. 后续需要补充的工作

在本包规划文档基础上，下一步需要完成：

1. 确定实际采用的 BunsenLabs 组件列表
2. 生成四个 `*.list.chroot` 文件初稿
3. 明确中文环境是否纳入第一版
4. 明确 Docker/Podman 是否纳入第一版
5. 明确 `openssh-server` 是否默认启用

---

## 12. 结论

软件包规划的核心不是“装尽可能多的软件”，而是：

- 保持底层稳定
- 保持桌面轻量
- 有选择地吸收 BunsenLabs 价值
- 让团队真正开机即用

首版应坚持“少而稳”，先跑通构建与安装，再逐步增加功能层。
