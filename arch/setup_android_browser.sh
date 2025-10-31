#!/bin/bash

# --- 环境声明 ---
# 此脚本设计为在 Android (如 Termux) 环境中运行的 ArchLinux chroot 内执行。
# 它依赖于 /proc/1/root 访问宿主 Android 系统。
#
# --- 运行要求 ---
# 此脚本必须通过 sudo 由普通用户运行，例如: sudo ./setup_android_browser.sh

# --- 1. 权限与用户检查 ---

if [ "$(id -u)" -ne 0 ]; then
    echo "错误：此脚本必须以 root 权限运行。" >&2
    echo "请尝试: sudo $0" >&2
    exit 1
fi

# 自动检测调用 sudo 的用户名
TARGET_USER="${SUDO_USER}"
if [ -z "${TARGET_USER}" ] || [ "${TARGET_USER}" = "root" ]; then
    echo "错误：请勿直接以 root 身份运行此脚本。" >&2
    echo "请使用普通用户通过 'sudo $0' 来运行。" >&2
    exit 1
fi

# 获取该用户的 Home 目录
USER_HOME=$(getent passwd "${TARGET_USER}" | cut -d: -f6)
if [ -z "${USER_HOME}" ]; then
    echo "错误：无法获取用户 ${TARGET_USER} 的主目录。" >&2
    exit 1
fi

echo "目标用户: ${TARGET_USER}"
echo "用户主目录: ${USER_HOME}"

# --- 2. 路径定义 ---

WRAPPER_SCRIPT="/usr/local/bin/open-in-android"
SUDOERS_FILE="/etc/sudoers.d/open-in-android"
DESKTOP_DIR="${USER_HOME}/.local/share/applications"
DESKTOP_FILE="${DESKTOP_DIR}/android-browser.desktop"

# --- 3. 依赖安装 ---

echo "正在检查并安装依赖 (zenity)..."

pacman -S --noconfirm --needed zenity
if [ $? -ne 0 ]; then
    echo "错误：依赖安装失败。" >&2
    exit 1
fi

# --- 4. 创建包装脚本 ---

echo "正在创建包装脚本 ${WRAPPER_SCRIPT}..."
mkdir -p "$(dirname "${WRAPPER_SCRIPT}")"

cat > "${WRAPPER_SCRIPT}" << 'EOF'
#!/bin/sh

URL="$1"

if zenity --question --title="安全确认" --text="即将尝试在 Android 中打开以下链接：\n\n<b>$URL</b>\n\n是否继续？"; then
    chroot /proc/1/root /system/bin/sh -c "export PATH=/system/bin; /system/bin/am start --user 0 -a android.intent.action.VIEW -d \"$URL\" > /dev/null"
else
    exit 1
fi
EOF

# 设置包装脚本的权限
chown root:root "${WRAPPER_SCRIPT}"
chmod 755 "${WRAPPER_SCRIPT}"

# --- 5. 配置免密 Sudo ---

echo "正在为 ${TARGET_USER} 配置免密 sudo..."
mkdir -p "$(dirname "${SUDOERS_FILE}")"
chmod 750 "$(dirname "${SUDOERS_FILE}")"

# 为自动检测到的用户配置 NOPASSWD
echo "${TARGET_USER} ALL=(root) NOPASSWD: ${WRAPPER_SCRIPT} *" > "${SUDOERS_FILE}"

# 设置 sudoers 文件的严格权限
chown root:root "${SUDOERS_FILE}"
chmod 640 "${SUDOERS_FILE}"

# 语法检查，防止锁死系统
visudo -c -f "${SUDOERS_FILE}"
if [ $? -ne 0 ]; then
    echo "错误：生成的 Sudoers 文件语法错误！正在移除..." >&2
    rm -f "${SUDOERS_FILE}"
    exit 1
fi

# --- 6. 创建 .desktop 文件 (降权执行) ---

echo "正在为用户 ${TARGET_USER} 创建 .desktop 文件并设为默认..."

# 切换到普通用户身份来执行 XDG/GUI 相关操作
sudo -u "${TARGET_USER}" /bin/bash << EOF_USER
# 确保目录存在
mkdir -p "${DESKTOP_DIR}"

# 写入 .desktop 文件
cat > "${DESKTOP_FILE}" << 'EOF_DESKTOP'
[Desktop Entry]
Name=Android Browser
Comment=通过 'am start' 在 Android 中打开
Exec=sudo /usr/local/bin/open-in-android %u
Terminal=false
Type=Application
MimeType=x-scheme-handler/http;x-scheme-handler/https;
Categories=Network;WebBrowser;
EOF_DESKTOP

# 更新 .desktop 数据库
update-desktop-database "${DESKTOP_DIR}"

# 设置为默认浏览器
xdg-settings set default-web-browser android-browser.desktop
EOF_USER

if [ $? -eq 0 ]; then
    echo "设置成功！"
    echo "'Android Browser' 已被设置为 ${TARGET_USER} 的默认浏览器。"
else
    echo "错误：用户级 .desktop 设置失败。" >&2
    exit 1
fi