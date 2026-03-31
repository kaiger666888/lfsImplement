#!/bin/bash
# ============================================================================
# Git LFS 统一配置脚本
# 功能：为指定仓库的多个分支自动添加 .gitattributes 配置
# 支持：本地路径和远程 URL
# 用法：./apply-lfs.sh <repo_path_or_url> <branches_file> [--dry-run] [--push]
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 默认配置
DRY_RUN=false
PUSH_CHANGES=false
CLEANUP_REPO=false
WORK_DIR=""
LFS_ATTRIBUTES_FILE=".gitattributes"

# LFS 配置内容
LFS_CONFIG='# Git LFS Configuration
# This file configures Git LFS to track large binary files

# ========== Android 特有文件 ==========
*.apk filter=lfs diff=lfs merge=lfs -text
*.aar filter=lfs diff=lfs merge=lfs -text
*.so filter=lfs diff=lfs merge=lfs -text

# ========== 压缩文件和归档 ==========
*.zip filter=lfs diff=lfs merge=lfs -text
*.jar filter=lfs diff=lfs merge=lfs -text
*.war filter=lfs diff=lfs merge=lfs -text
*.gz filter=lfs diff=lfs merge=lfs -text
*.tar filter=lfs diff=lfs merge=lfs -text
*.tar.gz filter=lfs diff=lfs merge=lfs -text
*.tgz filter=lfs diff=lfs merge=lfs -text
*.rar filter=lfs diff=lfs merge=lfs -text
*.7z filter=lfs diff=lfs merge=lfs -text
*.bz2 filter=lfs diff=lfs merge=lfs -text

# ========== 图片文件 ==========
*.png filter=lfs diff=lfs merge=lfs -text
*.jpg filter=lfs diff=lfs merge=lfs -text
*.jpeg filter=lfs diff=lfs merge=lfs -text
*.gif filter=lfs diff=lfs merge=lfs -text
*.webp filter=lfs diff=lfs merge=lfs -text
*.bmp filter=lfs diff=lfs merge=lfs -text
*.ico filter=lfs diff=lfs merge=lfs -text
*.tiff filter=lfs diff=lfs merge=lfs -text
*.psd filter=lfs diff=lfs merge=lfs -text
*.ai filter=lfs diff=lfs merge=lfs -text
*.sketch filter=lfs diff=lfs merge=lfs -text

# ========== 音频文件 ==========
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.flac filter=lfs diff=lfs merge=lfs -text
*.aac filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.wma filter=lfs diff=lfs merge=lfs -text
*.m4a filter=lfs diff=lfs merge=lfs -text
*.opus filter=lfs diff=lfs merge=lfs -text

# ========== 视频文件 ==========
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.avi filter=lfs diff=lfs merge=lfs -text
*.mkv filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.wmv filter=lfs diff=lfs merge=lfs -text
*.flv filter=lfs diff=lfs merge=lfs -text
*.webm filter=lfs diff=lfs merge=lfs -text
*.m4v filter=lfs diff=lfs merge=lfs -text
*.mpeg filter=lfs diff=lfs merge=lfs -text
*.mpg filter=lfs diff=lfs merge=lfs -text

# ========== 数据库文件 ==========
*.db filter=lfs diff=lfs merge=lfs -text
*.sqlite filter=lfs diff=lfs merge=lfs -text
*.sqlite3 filter=lfs diff=lfs merge=lfs -text

# ========== 数据和二进制文件 ==========
*.hdf5 filter=lfs diff=lfs merge=lfs -text
*.mf4 filter=lfs diff=lfs merge=lfs -text
*.a2l filter=lfs diff=lfs merge=lfs -text
*.cancfg filter=lfs diff=lfs merge=lfs -text
*.seq filter=lfs diff=lfs merge=lfs -text
*.trc filter=lfs diff=lfs merge=lfs -text
*.npy filter=lfs diff=lfs merge=lfs -text
*.npz filter=lfs diff=lfs merge=lfs -text
*.bin filter=lfs diff=lfs merge=lfs -text
*.dat filter=lfs diff=lfs merge=lfs -text
*.data filter=lfs diff=lfs merge=lfs -text

# ========== 字体文件 ==========
*.ttf filter=lfs diff=lfs merge=lfs -text
*.otf filter=lfs diff=lfs merge=lfs -text
*.woff filter=lfs diff=lfs merge=lfs -text
*.woff2 filter=lfs diff=lfs merge=lfs -text

# ========== 3D 模型文件 ==========
*.obj filter=lfs diff=lfs merge=lfs -text
*.fbx filter=lfs diff=lfs merge=lfs -text
*.gltf filter=lfs diff=lfs merge=lfs -text
*.glb filter=lfs diff=lfs merge=lfs -text
*.dae filter=lfs diff=lfs merge=lfs -text
*.stl filter=lfs diff=lfs merge=lfs -text

# ========== 机器学习模型文件 ==========
*.tflite filter=lfs diff=lfs merge=lfs -text
*.onnx filter=lfs diff=lfs merge=lfs -text
*.pt filter=lfs diff=lfs merge=lfs -text
*.pb filter=lfs diff=lfs merge=lfs -text
*.h5 filter=lfs diff=lfs merge=lfs -text

# ========== 排除规则 ==========
gradle/wrapper/gradle-wrapper.jar -diff -merge -filter
gradle-wrapper.jar -diff -merge -filter'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${CYAN}[STEP]${NC} $1"; }

# 打印帮助
print_help() {
    echo "Git LFS 统一配置脚本"
    echo ""
    echo "用法: $0 <repo> <branches_file> [options]"
    echo ""
    echo "参数:"
    echo "  repo            本地仓库路径 或 远程仓库 URL"
    echo "  branches_file   包含分支列表的文件（每行一个分支名）"
    echo ""
    echo "选项:"
    echo "  --dry-run       模拟执行，不实际修改"
    echo "  --push          完成后自动推送到远程"
    echo "  --help, -h      显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  # 本地仓库"
    echo "  $0 /path/to/repo branches.txt --dry-run"
    echo ""
    echo "  # 远程 URL"
    echo "  $0 git@github.com:user/repo.git branches.txt --dry-run"
    echo "  $0 https://github.com/user/repo.git branches.txt"
}

# 检查是否是 URL
is_url() {
    local input="$1"
    [[ "$input" =~ ^https?:// ]] || [[ "$input" =~ ^git@ ]] || [[ "$input" =~ ^ssh:// ]]
}

# 清理函数
cleanup() {
    if [ "$CLEANUP_REPO" = true ] && [ -n "$WORK_DIR" ] && [ -d "$WORK_DIR" ]; then
        log_info "清理临时目录: $WORK_DIR"
        rm -rf "$WORK_DIR"
    fi
}

# 检查依赖
check_dependencies() {
    local missing=()
    command -v git &> /dev/null || missing+=("git")
    command -v git-lfs &> /dev/null || missing+=("git-lfs")

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing[*]}"
        exit 1
    fi
}

# 处理单个分支
process_branch() {
    local branch=$1
    local original_branch
    original_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

    log_step "处理分支: ${YELLOW}$branch${NC}"

    # 检查远程分支是否存在
    if ! git ls-remote --heads origin "$branch" 2>/dev/null | grep -q "$branch"; then
        log_warning "  远程分支不存在: $branch，跳过"
        return 1
    fi

    # 获取远程分支
    log_info "  获取远程分支..."
    git fetch origin "$branch" --depth=1 2>/dev/null || {
        # 如果浅克隆失败，尝试完整获取
        git fetch origin "$branch" 2>/dev/null || {
            log_error "  获取分支失败: $branch"
            return 1
        }
    }

    # 创建或切换到本地分支
    if git show-ref --verify --quiet "refs/heads/$branch"; then
        git checkout "$branch" 2>/dev/null || {
            log_error "  切换分支失败"
            return 1
        }
        git reset --hard "origin/$branch" 2>/dev/null || true
    else
        git checkout -b "$branch" "origin/$branch" 2>/dev/null || {
            log_error "  创建本地分支失败"
            return 1
        }
    fi

    # 检查是否已存在 .gitattributes
    if [ -f "$LFS_ATTRIBUTES_FILE" ]; then
        log_warning "  已存在 .gitattributes 文件"
        if [ "$DRY_RUN" = false ]; then
            echo -n "  是否覆盖? (y/n): "
            read -r reply
            if [[ ! "$reply" =~ ^[Yy]$ ]]; then
                log_info "  跳过此分支"
                git checkout "$original_branch" 2>/dev/null || true
                return 0
            fi
        else
            log_info "  [DRY-RUN] 将覆盖现有文件"
        fi
    fi

    # 写入 LFS 配置
    if [ "$DRY_RUN" = true ]; then
        log_info "  [DRY-RUN] 将写入 .gitattributes"
        log_info "  [DRY-RUN] 将创建提交"
    else
        log_info "  写入 .gitattributes..."
        echo "$LFS_CONFIG" > "$LFS_ATTRIBUTES_FILE"
        git add "$LFS_ATTRIBUTES_FILE"

        if git diff --cached --quiet 2>/dev/null; then
            log_warning "  没有变更需要提交"
        else
            log_info "  创建提交..."
            git commit -m "chore: configure Git LFS for large binary files

This commit adds .gitattributes to track large binary files with Git LFS.
Only affects future commits, existing history is preserved." || {
                log_warning "  提交失败或没有变更"
            }
        fi
    fi

    # 推送
    if [ "$PUSH_CHANGES" = true ] && [ "$DRY_RUN" = false ]; then
        log_info "  推送到远程..."
        if git push origin "$branch" 2>/dev/null; then
            log_success "  推送成功: $branch"
        else
            log_error "  推送失败: $branch"
            return 1
        fi
    fi

    # 切回原分支
    git checkout "$original_branch" 2>/dev/null || true
    log_success "  完成: $branch"
    return 0
}

# 主函数
main() {
    local repo_input=""
    local branches_file=""

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --push)
                PUSH_CHANGES=true
                shift
                ;;
            --help|-h)
                print_help
                exit 0
                ;;
            *)
                if [ -z "$repo_input" ]; then
                    repo_input="$1"
                elif [ -z "$branches_file" ]; then
                    branches_file="$1"
                else
                    log_error "未知参数: $1"
                    print_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 验证参数
    if [ -z "$repo_input" ] || [ -z "$branches_file" ]; then
        log_error "缺少必要参数"
        print_help
        exit 1
    fi

    if [ ! -f "$branches_file" ]; then
        log_error "分支文件不存在: $branches_file"
        exit 1
    fi

    # 检查依赖
    check_dependencies

    # 设置清理陷阱
    trap cleanup EXIT

    # 判断输入类型并准备仓库
    local repo_path=""

    if is_url "$repo_input"; then
        log_info "检测到远程 URL，将克隆仓库..."
        WORK_DIR="/tmp/lfs-config-$$"
        CLEANUP_REPO=true
        mkdir -p "$WORK_DIR"

        log_info "克隆仓库: $repo_input"
        # 使用 --no-single-branch 获取所有分支信息
        git clone --no-single-branch "$repo_input" "$WORK_DIR/repo" || {
            log_error "克隆仓库失败"
            exit 1
        }
        repo_path="$WORK_DIR/repo"
    else
        log_info "检测到本地路径..."
        if [ ! -d "$repo_input/.git" ]; then
            log_error "不是有效的 Git 仓库: $repo_input"
            exit 1
        fi
        repo_path="$repo_input"
        CLEANUP_REPO=false
    fi

    cd "$repo_path" || exit 1

    # 初始化 Git LFS
    log_info "初始化 Git LFS..."
    git lfs install 2>/dev/null || true

    # 读取分支列表
    local branches=()
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | xargs)
        [ -n "$line" ] && [[ ! "$line" =~ ^# ]] && branches+=("$line")
    done < "$branches_file"

    if [ ${#branches[@]} -eq 0 ]; then
        log_error "分支文件中没有有效的分支名"
        exit 1
    fi

    log_info "找到 ${#branches[@]} 个分支需要处理"
    echo ""

    # 显示模式
    echo "=========================================="
    if [ "$DRY_RUN" = true ]; then
        log_warning "模式: 模拟执行 (DRY-RUN)"
    else
        log_info "模式: 实际执行"
    fi

    if [ "$PUSH_CHANGES" = true ]; then
        log_warning "将在完成后自动推送到远程"
    else
        log_info "不会自动推送（使用 --push 参数启用）"
    fi
    echo "=========================================="
    echo ""

    # 处理每个分支
    local success_count=0
    local fail_count=0

    for branch in "${branches[@]}"; do
        if process_branch "$branch"; then
            ((success_count++))
        else
            ((fail_count++))
        fi
        echo ""
    done

    # 打印摘要
    echo "=========================================="
    log_info "处理完成"
    echo "=========================================="
    log_success "成功: $success_count"
    if [ $fail_count -gt 0 ]; then
        log_error "失败: $fail_count"
    fi
    echo ""

    if [ "$DRY_RUN" = true ]; then
        log_warning "这是模拟执行，未实际修改任何内容"
        log_info "移除 --dry-run 参数以实际执行"
    fi

    if [ "$PUSH_CHANGES" = false ] && [ "$DRY_RUN" = false ]; then
        log_info "变更已提交到本地"
        log_info "手动推送命令: git push origin <branch>"
    fi

    exit $((fail_count > 0 ? 1 : 0))
}

# 执行主函数
main "$@"
