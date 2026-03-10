#!/bin/bash

# 颜色设置
BLUE='\033[0;34m'
GREEN='\033[0;32m'
BOLD='\033[1m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # 重置颜色

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}${BOLD}=== VSCode Remote SSH 环境一键配置脚本 ===${NC}\n"

# 检查是否以root身份运行
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}请勿以超级用户身份运行此脚本。${NC}"
    exit 1
fi

# 第一步：检查并安装 Anaconda/Miniconda
echo -e "${BLUE}${BOLD}步骤 1/3: 安装 Miniconda 并配置环境${NC}"
echo "============================================"

# 检查 miniconda3 是否已安装
if [ -d "$HOME/miniconda3" ] && [ -f "$HOME/miniconda3/bin/conda" ]; then
    echo -e "${YELLOW}检测到 Miniconda 已安装${NC}"
    echo -n -e "是否跳过 Miniconda 安装? (y/n): "
    read -r skip_anaconda
    
    if [[ "$skip_anaconda" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${GREEN}跳过 Miniconda 安装步骤${NC}"
        
        # 检查 libc_env 环境是否存在
        if "$HOME/miniconda3/bin/conda" env list | grep -q "libc_env"; then
            echo -e "${GREEN}检测到 libc_env 环境已存在${NC}"
        else
            echo -e "${YELLOW}libc_env 环境不存在，正在创建...${NC}"
            source "$HOME/miniconda3/etc/profile.d/conda.sh"
            "$HOME/miniconda3/bin/conda" create -n libc_env -y
            "$HOME/miniconda3/bin/conda" install -n libc_env sysroot_linux-64=2.28 patchelf -c conda-forge -y
            echo -e "${GREEN}libc_env 环境创建完成${NC}"
        fi
    else
        bash "$SCRIPT_DIR/setup_anaconda.sh"
    fi
else
    if [ -f "$SCRIPT_DIR/setup_anaconda.sh" ]; then
        bash "$SCRIPT_DIR/setup_anaconda.sh"
    else
        echo -e "${RED}错误: 找不到 setup_anaconda.sh 脚本${NC}"
        exit 1
    fi
fi

echo ""

# 第二步：配置 VSCode Server 补丁
echo -e "${BLUE}${BOLD}步骤 2/3: 配置 VSCode Server 补丁${NC}"
echo "============================================"

# 确保 conda 环境已初始化
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
fi

# 激活 libc_env 环境以使用其中的 patchelf
conda activate libc_env 2>/dev/null || true

if [ -f "$SCRIPT_DIR/setup_vscode_patch.sh" ]; then
    bash "$SCRIPT_DIR/setup_vscode_patch.sh"
else
    echo -e "${RED}错误: 找不到 setup_vscode_patch.sh 脚本${NC}"
    exit 1
fi

echo ""

# 第三步：配置 antigravity Server 补丁
echo -e "${BLUE}${BOLD}步骤 3/3: 配置 antigravity Server 补丁${NC}"
echo "============================================"

# 确保 conda 环境已初始化
if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
    source "$HOME/miniconda3/etc/profile.d/conda.sh"
fi

# 激活 libc_env 环境以使用其中的 patchelf
conda activate libc_env 2>/dev/null || true

if [ -f "$SCRIPT_DIR/setup_antigravity_patch.sh" ]; then
    bash "$SCRIPT_DIR/setup_antigravity_patch.sh"
else
    echo -e "${RED}错误: 找不到 setup_antigravity_patch.sh 脚本${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}${BOLD}=== 所有配置已完成！ ===${NC}\n"
echo -e "现在您可以使用 VSCode Remote SSH 连接到此服务器。"
echo -e "补丁脚本位置: ${BOLD}$HOME/.ssh/patch_all_code_servers.sh${NC}"
echo -e "\n${YELLOW}提示：${NC}如果之后需要重新应用补丁，请运行:"
echo -e "  ${BOLD}bash $HOME/.ssh/patch_all_code_servers.sh${NC}"
