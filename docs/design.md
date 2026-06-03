# 基于 Debian live-build + BunsenLabs 组件的团队定制 ISO 设计方案

## 1. 目标

本方案用于指导构建一个**面向内部团队使用**的桌面 Linux ISO，技术路线采用：

- **底座**：Debian stable
- **构建工具**：`live-build`
- **桌面体验参考/继承**：按需引入 BunsenLabs 的 Openbox、主题、脚本、配置思路
- **安装器**：Calamares
- **品牌层**：替换为团队自己的名称、Logo、壁纸、欢迎页与默认文案
- **用途边界**：仅供团队内部部署与使用，不以对外公开发行版为目标

该方案的核心思想是：

> 不复刻 BunsenLabs 官方完整发行工程，而是以 Debian live-build 为主线，按需吸收 BunsenLabs 可复用组件，构建一个可重复生成、可维护、可安装的团队 ISO。

---

## 2. 设计原则

### 2.1 可重复构建

所有构建过程必须脚本化、版本化，避免手工进入 chroot 修改系统。

### 2.2 薄依赖上游

BunsenLabs 仅作为桌面风格、主题、配置、脚本的来源之一，不将整个发行工程绑定到其全部仓库结构或 ISO 构建实现。

### 2.3 品牌与配置自主管理

系统名称、Logo、壁纸、欢迎页、默认菜单、团队软件、首次启动逻辑均由本项目自维护。

### 2.4 面向内部团队使用

优先保障：
- 安装方便
- 桌面一致
- 工具齐全
- 可快速重建
- 可控升级

不优先追求：
- 外部社区发行
- 自建完整软件仓库
- 多架构支持
- 深度修改安装器逻辑

---

## 3. 总体架构

整个团队 ISO 由五层组成：

### 3.1 基础系统层

- Debian stable 基础软件包
- 内核、systemd、APT、基础命令行工具
- 网络与证书基础设施

### 3.2 Live 构建层

由 `live-build` 负责：

- 构建 live root filesystem
- 生成启动镜像
- 组装 ISO
- 处理 chroot 阶段与 binary 阶段资源注入

### 3.3 桌面体验层

引入：

- Openbox
- Tint2
- 文件管理器
- 终端
- 浏览器
- 部分 BunsenLabs 风格配置、主题、脚本

### 3.4 品牌定制层

覆盖与注入：

- `/etc/os-release`
- 壁纸
- Logo
- 启动画面
- Calamares branding
- 桌面菜单名称与欢迎页文案

### 3.5 团队环境层

由团队维护：

- 预装软件
- `/etc/skel` 默认用户配置
- 团队文档入口
- 首次启动脚本
- 团队网络、证书、开发工具初始化逻辑

---

## 4. 与 BunsenLabs 的关系

### 4.1 采用方式

本项目**不是直接 fork BunsenLabs 官方发行版**，而是：

- 使用 Debian live-build 构建 ISO
- 按需接入 BunsenLabs 仓库中的可复用包
- 借鉴或继承 BunsenLabs 的 Openbox 桌面体验与部分资源

### 4.2 推荐继承内容

优先考虑从 BunsenLabs 继承：

- Openbox 体验设计
- 主题资源
- 菜单与桌面辅助脚本
- 默认桌面配置思路

### 4.3 不建议直接依赖的内容

初期不建议深度依赖：

- 官方 ISO 构建全流程
- 全量 BunsenLabs 仓库包
- 上游完整品牌资源
- 上游安装器工程的深层定制实现

### 4.4 设计目标

通过“选择性复用 + 自主覆盖”，最终形成：

- 构建链路属于团队自己
- 品牌归属属于团队自己
- 配置和软件集合属于团队自己
- 上游变更不会直接卡死团队版本迭代

---

## 5. 推荐目录结构

建议建立独立构建仓库，例如：`team-os-build`

```text
team-os-build/
├── README.md
├── build.sh
├── config/
│   ├── package-lists/
│   │   ���── base.list.chroot
│   │   ├── desktop.list.chroot
│   │   ├── bunsen.list.chroot
│   │   └── team.list.chroot
│   ├── archives/
│   │   └── bunsenlabs.list.chroot
│   ├── includes.chroot/
│   │   ├── etc/
│   │   │   ├── os-release
│   │   │   ├── issue
│   │   │   ├── issue.net
│   │   │   └── skel/
│   │   ├── usr/share/
│   │   │   ├── backgrounds/
│   │   │   ├── icons/
│   │   │   └── applications/
│   │   └── usr/local/bin/
│   ├── includes.binary/
│   ├── hooks/
│   │   ├── normal/
│   │   └── live/
│   └── bootloaders/
├── branding/
│   ├── wallpapers/
│   ├── logos/
│   ├── grub/
│   ├── plymouth/
│   └── calamares/
└── docs/
    ├── design.md
    ├── package-plan.md
    └── release-checklist.md
```

---

## 6. 软件包分层设计

### 6.1 base 层

包含最小可运行系统：

- systemd
- sudo
- curl
- wget
- ca-certificates
- openssh-client
- network-manager
- locales
- bash-completion

### 6.2 desktop 层

包含基础桌面体验：

- xorg
- openbox
- tint2
- obconf
- nitrogen
- 文件管理器（如 thunar 或 pcmanfm）
- 终端（如 xfce4-terminal）
- 浏览器（如 firefox-esr）
- lightdm（如采用图形登录）

### 6.3 bunsen 风格层

按需挑选：

- BunsenLabs 主题包
- 桌面辅助脚本
- Openbox 配置模板
- 菜单增强项

注意：此层应采用“白名单包策略”，不做全量安装。

### 6.4 team 层

内部团队软件：

- git
- vim / neovim
- 编程语言运行时（视团队需要）
- 容器工具（docker / podman）
- VPN 客户端
- 内网证书导入工具
- 团队自有脚本

---

## 7. 品牌替换设计

### 7.1 必须替换的文本标识

- `/etc/os-release`
- `/etc/issue`
- `/etc/issue.net`
- GRUB 菜单标题
- ISO volume label
- Live 启动菜单文案
- Calamares 产品名称
- 欢迎页文案
- 浏览器默认主页标题

### 7.2 必须替换的图形资源

- 桌面壁纸
- 系统 Logo
- 启动背景图
- Plymouth 资源
- GRUB 背景图
- Calamares branding 图
- 欢迎页图标

### 7.3 残留扫描机制

每次构建后增加品牌扫描步骤，检查是否仍出现以下关键词：

- `BunsenLabs`
- `Bunsen`
- 上游发行代号
- 临时项目名称

建议在构建完成后对以下目录做扫描：

- `/etc`
- `/usr/share`
- `/usr/local`
- `/home/*/.config`

---

## 8. 用户环境设计

### 8.1 默认用户配置

通过 `/etc/skel` 统一提供：

- Openbox 配置
- Tint2 配置
- Conky 配置（若启用）
- GTK 主题配置
- 终端配置
- 浏览器书签
- 团队快捷方式

### 8.2 首次启动逻辑

首次启动脚本负责：

- 欢迎信息展示
- 团队文档入口提示
- 可选的软件源初始化
- 内网证书或代理设置提示
- 团队脚本首次配置

### 8.3 桌面交互目标

用户安装后应达到以下体验：

- 开机即进入统一桌面环境
- 可立即联网
- 可直接打开团队常用工具
- 可快速访问团队文档与内部资源

---

## 9. 安装器设计

### 9.1 安装器选型

采用 **Calamares** 作为安装器。

### 9.2 第一阶段目标

第一版仅做：

- 安装器接入
- 基础 branding
- 默认语言/时区/键盘选项微调
- 安装完成页文案替换

### 9.3 暂不纳入范围

第一版不包含：

- 自定义分区模块
- 深度安装流程改造
- 自定义复杂安装逻辑

### 9.4 设计原则

优先使用 Calamares 已有能力完成团队安装体验，不在初期引入自研安装器复杂度。

---

## 10. 构建流程设计

### 10.1 推荐流程

1. 准备 Debian 构建环境
2. 初始化 `live-build` 配置
3. 添加 Debian stable 软件源
4. 添加 BunsenLabs 软件源与 keyring
5. 安装分层 package lists
6. 注入 branding 文件
7. 注入 `/etc/skel` 与团队脚本
8. 注入 hooks
9. 执行 ISO 构建
10. 在虚拟机中测试 Live 启动与安装流程

### 10.2 输出物

每次构建至少产生：

- ISO 文件
- 构建日志
- 版本号/构建时间记录
- 基础测试结果记录

### 10.3 构建约束

- 所有构建输入必须纳入 Git 管理
- 不允许依赖人工进入 chroot 修改产物
- 每次构建都应可由脚本重新生成

---

## 11. 测试策略

### 11.1 第一阶段测试重点

- ISO 可启动
- Live 桌面可进入
- 网络可用
- 终端、文件管理器、浏览器可用
- 团队 Logo 与系统名称已生效

### 11.2 第二阶段测试重点

- Calamares 启动正常
- 可完成安装
- 重启后可进入已安装系统
- `/etc/skel` 模板正确应用
- 首次启动脚本正常执行

### 11.3 测试环境建议

- QEMU/KVM
- VirtualBox（可选）
- 至少一台真实机器做启动验证

---

## 12. 项目分期

### Phase 1：Live 原型版

目标：

- 跑通 live-build
- 启动 Openbox Live 桌面
- 替换基础品牌
- 加入团队基础软件

交付物：

- 可启动的 Live ISO
- 初版桌面环境
- 品牌替换基本完成

### Phase 2：可安装版

目标：

- 接入 Calamares
- 提供安装能力
- 完成 `/etc/skel` 模板
- 加入欢迎页与首次启动逻辑

交付物：

- 可安装的团队 ISO
- 安装后桌面与配置统一

### Phase 3：可维护版

目标：

- 脚本化构建
- 完善版本标识
- 补充测试记录
- 输出发布检查清单

交付物：

- 可重复构建流程
- 稳定内部发布版本

---

## 13. 风险与控制

### 13.1 风险：品牌替换不彻底

控制措施：

- 建立关键词扫描检查
- 对安装器、桌面菜单、欢迎页做专项检查

### 13.2 风险：对上游仓库依赖过重

控制措施：

- 白名单方式引入 BunsenLabs 包
- 尽量把配置和脚本沉淀到自有仓库

### 13.3 风险：安装器集成耗时超预期

控制措施：

- 第一阶段先完成 Live ISO
- 安装器放到第二阶段单独推进

### 13.4 风险：后续维护困难

控制措施：

- 从第一天开始脚本化
- 目录结构固定
- 所有覆盖文件纳入版本控制

---

## 14. 推荐的第一版边界

### 必须完成

- Debian live-build 跑通
- Openbox Live 桌面
- 团队名称替换
- 团队 Logo 与壁纸替换
- 基础团队软件预装

### 建议完成

- Calamares branding
- `/etc/skel` 默认配置
- 欢迎页
- 首次启动脚本

### 暂缓完成

- 自建 APT 仓库
- 自建更新通道
- 多架构支持
- 深改安装器逻辑
- 外部发布级别兼容性适配

---

## 15. 结论

方案 A 是当前最适合团队内部场景的技术路径。

它避免了完整 fork 发行版的高维护成本，同时保留了：

- Debian 稳定底座
- BunsenLabs 的轻量桌面风格价值
- 团队独立品牌与配置控制权
- ISO 可重复构建与后续可维护性

后续实施建议按照以下顺序推进：

1. 先做 Live ISO 原型
2. 再加入安装器
3. 最后补齐可维护与测试体系

---

## 16. 后续文档建议

在本设计文档基础上，后续建议继续补充：

- `package-plan.md`：列出最终采用的软件包清单
- `branding-checklist.md`：列出所有品牌替换点
- `build-runbook.md`：记录完整构建步骤
- `release-checklist.md`：记录每次发布前检查项
