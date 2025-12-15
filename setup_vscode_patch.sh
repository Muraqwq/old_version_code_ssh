#!/bin/bash

# 定义颜色
BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # 无颜色

# 总步骤数
TOTAL_STEPS=3
CURRENT_STEP=0

# 打印进度消息的函数
print_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENTAGE=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -e "${BLUE}[${PERCENTAGE}%] ${BOLD}步骤 ${CURRENT_STEP}/${TOTAL_STEPS}:${NC} ${GREEN}$1${NC}"
}

# 检查当前用户是否为root用户
if [ "$EUID" -eq 0 ]; then
    echo "请勿以超级用户身份运行此脚本。"
    exit 1
fi

# 获取patchelf的路径
PATCHELF_PATH=$(which patchelf)

# 检查patchelf路径是否存在
if [ ! -x "$PATCHELF_PATH" ]; then
    echo "错误: 未安装patchelf或路径无效，请先运行setup_anaconda.sh安装。"
    exit 1
fi

# 创建补丁脚本路径
PATCH_SCRIPT="$HOME/.ssh/patch_all_code_servers.sh"
print_progress "创建补丁脚本"

# 创建补丁脚本
cat << EOF > "$PATCH_SCRIPT"
#!/bin/bash

# 定义glibc路径变量
VSCODE_SERVER_CUSTOM_GLIBC_PATH="\$HOME/miniconda3/envs/libc_env/x86_64-conda-linux-gnu/sysroot/lib"
VSCODE_SERVER_CUSTOM_GLIBC_LINKER="\$HOME/miniconda3/envs/libc_env/x86_64-conda-linux-gnu/sysroot/lib/ld-linux-x86-64.so.2"

# 定义VSCode服务器的根目录
VSCODE_SERVER_ROOT="\$HOME/.vscode-server/bin"

# 检查VSCode服务器根目录是否存在
if [ ! -d "\$VSCODE_SERVER_ROOT" ]; then
    exit 1
fi

# 检查patchelf是否安装
if [ ! -x "$PATCHELF_PATH" ]; then
    exit 1
fi

# 获取patchelf的路径
PATCHELF_PATH="$PATCHELF_PATH"

# 迭代每个子目录
for dir in "\$VSCODE_SERVER_ROOT"/*; do
    if [ -d "\$dir" ]; then
        # 定义node路径
        CODE_SERVER_NODE_PATH="\$dir/node"
        
        # 检查node文件是否存在
        if [ ! -f "\$CODE_SERVER_NODE_PATH" ]; then
            continue
        fi

        # 获取当前的解释器
        CURRENT_INTERPRETER=\$(\$PATCHELF_PATH --print-interpreter "\$CODE_SERVER_NODE_PATH" 2>/dev/null)

        # 检查并应用补丁
        if [ "\$CURRENT_INTERPRETER" != "\$VSCODE_SERVER_CUSTOM_GLIBC_LINKER" ]; then
            \$PATCHELF_PATH --set-rpath "\$VSCODE_SERVER_CUSTOM_GLIBC_PATH:/lib:/lib64:/lib/x86_64-linux-gnu:/usr/lib:/usr/lib64:/usr/lib/x86_64-linux-gnu:/usr/local/lib" "\$CODE_SERVER_NODE_PATH"
            \$PATCHELF_PATH --set-interpreter "\$VSCODE_SERVER_CUSTOM_GLIBC_LINKER" "\$CODE_SERVER_NODE_PATH"
            echo "补丁应用成功：\$CODE_SERVER_NODE_PATH"
        fi
    fi
done
EOF

# 赋予patch脚本执行权限
chmod +x "$PATCH_SCRIPT"
print_progress "赋予补丁脚本执行权限"

# 执行补丁脚本
print_progress "执行补丁脚本"
"$PATCH_SCRIPT"

# 提示用户
echo "设置完成！补丁脚本已保存到: $PATCH_SCRIPT"
echo "如需重新应用补丁，请执行: $PATCH_SCRIPT"
