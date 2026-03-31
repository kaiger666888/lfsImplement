#!/bin/bash
# ============================================================================
# Git LFS 本地仓库配置脚本
# 功能：在本地已有仓库上为多个分支添加 .gitattributes 配置
# 用法：./apply-lfs-local.sh <repo_path> <branches_file> [--dry-run] [--push]
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认配置
DRY_RUN=false
PUSH_CHANGES=false
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

# 打印帮助
print_help() {
    echo "Git LFS 本地仓库配置脚本"
    echo ""
    echo "用法: $0 <repo_path> <branches_file> [options]"
    echo ""
    echo "参数:"
    echo "  repo_path       本地仓库路径"
    echo "  branches_file   包含分支列表的文件"
    echo ""
    echo "选项:"
    echo "  --dry-run       模拟执行"
    echo "  --push          完成后推送"
    echo "  --help          显示帮助"
}

# 处理单个分支
process_branch() {
    local branch=$1
    local original_branch=$(git rev-parse --abbrev-ref HEAD)

    log_info "处理分支: ${YELLOW}$branch${NC}"

    # 检查分支是否存在
    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        # 尝试从远程获取
        log_info "  本地不存在，尝试从远程获取..."
        git fetch origin "$branch" 2>/dev/null || {
            log_warning "  远程分支也不存在，跳过"
            return 1
        }
        git checkout -b "$branch" "origin/$branch" 2>/dev/null || {
            log_error "  创建本地分支失败"
            return 1
        }
    else
        git checkout "$branch" 2>/dev/null || {
            log_error "  切换分支失败"
            return 1
        }
    fi

    # 检查是否已存在 .gitattributes
    if [ -f "$LFS_ATTRIBUTES_FILE" ]; then
        log_warning "  已存在 .gitattributes 文件"
        if [ "$DRY_RUN" = false ]; then
            read -p "  是否覆盖? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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
        echo "$LFS_CONFIG" > "$LFS_ATTRIBUTES_FILE"
        git add "$LFS_ATTRIBUTES_FILE"

        if git diff --cached --quiet; then
            log_warning "  没有变更需要提交"
        else
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
        git push origin "$branch" 2>/dev/null && {
            log_success "  推送成功"
        } || {
            log_error "  推送失败"
        }
    fi

    # 切回原分支
    git checkout "$original_branch" 2>/dev/null || true
    log_success "  完成: $branch"
    return 0
}

# 主函数
main() {
    local repo_path=""
    local branches_file=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run) DRY_RUN=true; shift ;;
            --push) PUSH_CHANGES=true; shift ;;
            --help|-h) print_help; exit 0 ;;
            *)
                if [ -z "$repo_path" ]; then
                    repo_path="$1"
                elif [ -z "$branches_file" ]; then
                    branches_file="$1"
                else
                    log_error "未知参数: $1"; exit 1
                fi
                shift
                ;;
        esac
    done

    [ -z "$repo_path" ] || [ -z "$branches_file" ] && {
        log_error "缺少参数"
        print_help
        exit 1
    }

    [ ! -d "$repo_path/.git" ] && {
        log_error "不是有效的 Git 仓库: $repo_path"
        exit 1
    }

    [ ! -f "$branches_file" ] && {
        log_error "分支文件不存在: $branches_file"
        exit 1
    }

    cd "$repo_path"

    # 初始化 Git LFS
    log_info "初始化 Git LFS..."
    git lfs install 2>/dev/null || true

    # 读取分支列表
    local branches=()
    if [ ! -f "$branches_file" ]; then
        log_error "分支文件不存在: $branches_file (当前目录: $(pwd))"
        exit 1
    fi
    while IFS= read -r line || [ -n "$line" ]; do
        line=$(echo "$line" | xargs)
        [ -n "$line" ] && [[ ! "$line" =~ ^# ]] && branches+=("$line")
    done < "$branches_file"

    log_info "找到 ${#branches[@]} 个分支需要处理"

    [ "$DRY_RUN" = true ] && log_warning "模式: 模拟执行 (DRY-RUN)"
    [ "$PUSH_CHANGES" = true ] && log_warning "将在完成后自动推送"

    echo ""
    log_info "=========================================="

    local success=0 fail=0
    for branch in "${branches[@]}"; do
        process_branch "$branch" && ((success++)) || ((fail++))
        echo ""
    done

    log_info "=========================================="
    log_success "成功: $success"
    [ $fail -gt 0 ] && log_error "失败: $fail"
}

main "$@"
