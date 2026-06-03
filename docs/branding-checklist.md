# 品牌替换检查清单

## 1. 文档目标

本文档用于梳理团队定制 ISO 中所有需要替换的品牌标识、名称、Logo、壁纸、启动资源与文案位置，确保最终产物不残留不必要的上游品牌信息，并形成可重复检查的品牌审计清单。

适用范围：

- Live ISO
- 安装后的系统
- 启动菜单
- 桌面会话
- 安装器界面
- 欢迎页与团队入口

---

## 2. 替换原则

### 2.1 自有品牌优先

所有面向最终用户可见的位置，统一替换为团队自有名称、Logo 和文案。

### 2.2 上游引用保留在文档层

如需说明系统来源，可在：

- `README.md`
- `docs/design.md`
- `docs/build-runbook.md`

中说明“基于 Debian live-build + 部分 BunsenLabs 组件构建”。

不建议在终端欢迎、桌面菜单、安装器主界面保留 BunsenLabs 品牌作为主要展示。

### 2.3 可扫描、可审计

所有替换点应尽量落在可版本控制的文件中，并能通过关键词搜索检查是否还有残留。

---

## 3. 品牌基础信息模板

以下字段建议先确定，并作为全局替换变量：

```text
TEAM_DISTRO_NAME=
TEAM_DISTRO_ID=
TEAM_DISTRO_PRETTY_NAME=
TEAM_VENDOR_NAME=
TEAM_WEBSITE=
TEAM_SUPPORT_URL=
TEAM_DOC_URL=
TEAM_LOGO_MAIN=
TEAM_LOGO_ICON=
TEAM_WALLPAPER_DEFAULT=
TEAM_RELEASE_CODENAME=
TEAM_ISO_LABEL=
```

建议在后续构建脚本中统一引用，避免散落硬编码。

---

## 4. 必须替换的文本标识

### 4.1 系统识别文件

#### `/etc/os-release`

检查项：

- `NAME`
- `VERSION`
- `ID`
- `ID_LIKE`
- `PRETTY_NAME`
- `HOME_URL`
- `SUPPORT_URL`
- `BUG_REPORT_URL`

目标：

- 名称显示为团队发行名称
- URL 指向团队文档或内部支持页

#### `/etc/issue`
#### `/etc/issue.net`

检查项：

- 登录前欢迎语
- 终端欢迎文本

目标：

- 不出现 BunsenLabs / Debian 之外的无关上游展示
- 使用团队标准欢迎语

---

### 4.2 Live 启动菜单文案

检查范围：

- GRUB 启动菜单标题
- GRUB 菜单项描述
- ISO 启动欢迎文本
- 安全模式/安装模式菜单项名称

目标：

- 显示团队名称
- 启动项命名一致
- 不暴露原始项目名作为主菜单标题

---

### 4.3 安装器文案

检查范围：

- Calamares 窗口标题
- 左侧导航中的产品名
- 欢迎页文案
- 安装完成页文案
- slideshow 文本（如启用）

目标：

- 所有主标题统一使用团队发行名称
- 安装完成提示引导到团队文档与支持资源

---

### 4.4 桌面菜单与快捷入口

检查范围：

- Openbox 菜单标题
- 桌面右键菜单帮助项
- “About”/“Welcome”/“Help” 类入口
- 浏览器默认书签
- 面板快捷入口说明文字

目标：

- 保留功能，但替换品牌和链接

---

### 4.5 应用描述和桌面文件

检查范围：

- `/usr/share/applications/*.desktop`
- 自定义 `desktop` 文件中的 `Name=`、`Comment=`、`Exec=`

目标：

- 避免默认菜单中出现上游发行品牌说明
- 团队工具入口命名统一

---

## 5. 必须替换的图形资源

### 5.1 桌面壁纸

检查项：

- 默认桌面壁纸
- 锁屏/登录背景（如配置）
- 欢迎页背景图

目标：

- 使用团队壁纸
- 不使用原版 BunsenLabs 品牌型壁纸

建议放置路径：

```text
branding/wallpapers/
config/includes.chroot/usr/share/backgrounds/
```

---

### 5.2 Logo 资源

检查项：

- 主 Logo
- 图标型 Logo
- 应用菜单图标
- 安装器 Logo
- 文档页图标

目标：

- 所有核心入口统一视觉识别

建议放置路径：

```text
branding/logos/
config/includes.chroot/usr/share/icons/
```

---

### 5.3 启动图与引导资源

检查范围：

- GRUB 背景图
- Plymouth 主题图
- LightDM greeter 图
- ISO 启动页背景

目标：

- 启动到桌面全链路视觉一致

---

### 5.4 安装器图形资源

检查范围：

- Calamares sidebar 图片
- 欢迎页配图
- 安装完成页图标
- slideshow 图片（如启用）

目标：

- 安装体验与 Live 桌面品牌一致

---

## 6. 重点品牌残留排查目录

构建完成后，建议重点扫描以下目录：

```text
/etc
/usr/share
/usr/local
/var/lib
/home/*/.config
```

重点文件类型：

- `.desktop`
- `.service`
- `.conf`
- `.xml`
- `.sh`
- `.json`
- `.yaml`
- `.css`
- `.svg`
- `.png`

---

## 7. 关键词扫描清单

每次构建后至少扫描以下关键词：

```text
BunsenLabs
Bunsen
Debian GNU/Linux
Lithium
Helium
Boron
Hydrogen
```

> 注：代号项可根据你实际复用的上游版本补充或裁剪。

如果你已经为团队发行版起名，也应扫描临时名称，防止测试阶段残留。

---

## 8. 分模块检查清单

### 8.1 系统身份

- [ ] `/etc/os-release` 已替换
- [ ] `/etc/issue` 已替换
- [ ] `/etc/issue.net` 已替换
- [ ] 终端登录欢迎语无上游品牌残留

### 8.2 启动链路

- [ ] GRUB 标题已替换
- [ ] GRUB 背景已替换
- [ ] ISO label 已替换
- [ ] Plymouth 主题已替换或禁用默认上游主题

### 8.3 图形登录

- [ ] LightDM 标题/greeter 资源已替换
- [ ] 登录背景与 Logo 已替换

### 8.4 桌面环境

- [ ] 默认壁纸已替换
- [ ] Openbox 菜单无上游品牌残留
- [ ] Tint2 / Conky / Rofi 中无旧名称
- [ ] 浏览器书签和首页已替换

### 8.5 安装器

- [ ] Calamares 品牌名称已替换
- [ ] sidebar 图片已替换
- [ ] 完成页链接已替换
- [ ] 幻灯片文案已替换

### 8.6 文档与入口

- [ ] Welcome 页面已替换
- [ ] 帮助菜单链接指向团队文档
- [ ] README 与设计文档保留上游来源说明

---

## 9. 建议的品牌资源目录

建议在仓库中统一组织品牌资源：

```text
branding/
├── logos/
│   ├── main.svg
│   ├── icon.svg
│   └── installer-sidebar.png
├── wallpapers/
│   ├── default.jpg
│   └── lockscreen.jpg
├── grub/
│   └── background.png
├── plymouth/
│   └── team-theme/
├── lightdm/
│   └── greeter.conf
└── calamares/
    ├── branding.desc
    ├── welcome.png
    └── finished.png
```

---

## 10. 审计方法建议

### 10.1 文本审计

在构建产物或 overlay 目录中执行：

```bash
grep -RniE 'BunsenLabs|Bunsen|Lithium|Helium|Hydrogen|Boron' config/includes.chroot/ branding/
```

如需对 ISO 安装后的根文件系统做审计，可在 chroot 或挂载环境下执行同类检查。

### 10.2 图像审计

建议人工确认以下界面截图：

- GRUB
- Live 桌面
- 登录界面
- 安装器欢迎页
- 安装器完成页
- 首次启动欢迎页

### 10.3 功能审计

检查以下入口是否仍指向上游：

- 浏览器主页
- 文档链接
- 菜单“Help”项
- 安装完成后的“Read documentation”入口

---

## 11. 初版执行建议

第一版不必追求所有视觉细节都极致统一，但至少要做到：

- 系统名称统一
- 默认壁纸统一
- 主 Logo 统一
- 安装器品牌统一
- 欢迎页和帮助链接统一

这五项完成后，团队成员的主观感受就会明显从“某个上游系统”变成“团队自己的系统”。

---

## 12. 结论

品牌替换不是简单换一个壁纸，而是覆盖：

- 系统身份
- 启动链路
- 桌面视觉
- 安装体验
- 文档和入口链接

建议将本文档作为每次版本发布前的必检项，并在后续自动化中加入关键词扫描步骤，避免品牌残留回流。
