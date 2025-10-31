# termux-arch-chroot

Android chroot ArchLinux 的脚本和教程

#### 📁 arch

> 此文件夹存放 chroot archlinux 实用脚本

**setup_android_browser.sh**

自动化安装脚本。配置 Arch chroot，使其调用 Android 宿主浏览器 (通过 am start) 作为默认浏览器打开链接。可以粘贴以下命令快速应用

```bash
curl -LO "https://raw.githubusercontent.com/miniyu157/termux-arch-chroot/refs/heads/main/setup_android_browser.sh" && chmod +x setup_android_browser.sh && sudo ./setup_android_browser.sh && rm setup_android_browser.sh
```

#### 📁 termux-scripts

> 此文件夹存放在 termux 环境下运行的实用脚本

**→ 📁 local_bin/**

termux-change-font 
- 自定义 termux 的字体

mt-editor, mt-locale
- 调用 MT管理器 (bin.mt.plus) 定位文件与编辑文件

arch-backup, arch-restore, arch-safe, arch-umount
- 管理 chroot 根文件系统

**→ 📁⚡️ termux_widget_dynamic_shortcuts/**

> 此文件夹位于 `/data/date/com.termux/files/home/.termux/widget/dynamic_shortcuts/` 推荐搭配 [termux-widget](https://github.com/termux/termux-widget/releases) 使用

ArchDesktop, ArchTty
- 桌面启动器 (xfce4) 和命令行启动器

创建软连接以便命令行可用

```bash
ln -s /data/data/com.termux/files/home/.termux/widget/dynamic_shortcuts/ArchDesktop ~/.local/bin/arch-desktop && ln -s /data/data/com.termux/files/home/.termux/widget/dynamic_shortcuts/ArchTty ~/.local/bin/arch
```
