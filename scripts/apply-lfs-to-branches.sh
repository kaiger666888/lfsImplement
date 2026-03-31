#!/bin/bash
# ============================================================================
# Git LFS 批量分支配置脚本
# 功能：为指定仓库的多个分支自动添加 .gitattributes 配置
# 用法：./apply-lfs-to-branches.sh <repo_url> <branches_file> [--dry-run] [--push]
# ============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DRY_RUN=false
PUSH_CHANGES=false
WORK_DIR="/tmp/lfs-migration-$$"
LFS_ATTRIBUTES_FILE=".gitattributes"
COMMIT_MSG="chore: configure Git LFS for large binary files

This commit adds .gitattributes to track large binary files with Git LFS.
Only affects future commits, existing history is preserved.

File types tracked:
- Android: apk, aar, so
- Archives: zip, jar, tar.gz, etc.
- Images: png, jpg, gif, webp, etc.
- Audio: mp3, wav, flac, etc.
- Video: mp4, avi, mkv, etc.
- Models: tflite, onnx, pt, etc.
- Data: bin, dat, db, etc."

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

# ========== 图片文件（二进制，Git 无法 diff）==========
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
*.xd filter=lfs diff=lfs merge=lfs -text
*.fig filter=lfs diff=lfs merge=lfs -text

# ========== 音频文件类型 ==========
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text
*.flac filter=lfs diff=lfs merge=lfs -text
*.aac filter=lfs diff=lfs merge=lfs -text
*.ogg filter=lfs diff=lfs merge=lfs -text
*.wma filter=lfs diff=lfs merge=lfs -text
*.m4a filter=lfs diff=lfs merge=lfs -text
*.opus filter=lfs diff=lfs merge=lfs -text
*.aiff filter=lfs diff=lfs merge=lfs -text

# ========== 视频文件类型 ==========
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
*.3gp filter=lfs diff=lfs merge=lfs -text
*.ts filter=lfs diff=lfs merge=lfs -text

# ========== 数据库文件 ==========
*.sddb filter=lfs diff=lfs merge=lfs -text
*.db filter=lfs diff=lfs merge=lfs -text
*.sqlite filter=lfs diff=lfs merge=lfs -text
*.sqlite3 filter=lfs diff=lfs merge=lfs -text
*.db-shm filter=lfs diff=lfs merge=lfs -text
*.db-wal filter=lfs diff=lfs merge=lfs -text

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
*.eot filter=lfs diff=lfs merge=lfs -text

# ========== 3D 模型和设计文件 ==========
*.obj filter=lfs diff=lfs merge=lfs -text
*.fbx filter=lfs diff=lfs merge=lfs -text
*.gltf filter=lfs diff=lfs merge=lfs -text
*.glb filter=lfs diff=lfs merge=lfs -text
*.dae filter=lfs diff=lfs merge=lfs -text
*.3ds filter=lfs diff=lfs merge=lfs -text
*.stl filter=lfs diff=lfs merge=lfs -text

# ========== 机器学习模型文件 ==========
*.tflite filter=lfs diff=lfs merge=lfs -text
*.onnx filter=lfs diff=lfs merge=lfs -text
*.pt filter=lfs diff=lfs merge=lfs -text
*.pb filter=lfs diff=lfs merge=lfs -text
*.h5 filter=lfs diff=lfs merge=lfs -text

# ========== 排除规则（不需要 LFS 的特殊文件）==========
# Gradle Wrapper JAR（构建工具核心文件，约 53KB，无需 LFS）
gradle/wrapper/gradle-wrapper.jar -diff -merge -filter
gradle-wrapper.jar -diff -merge -filter'

# 打印帮助信息
print_help() {
    echo "Git LFS 批量分支配置脚本"
    echo ""
    echo "用法: $0 <repo_url> <branches_file> [options]"
    echo ""
    echo "参数:"
    echo "  repo_url        Git 仓库的远程 URL"
    echo "  branches_file   包含分支列表的文件（每行一个分支名）"
    echo ""
    echo "选项:"
    echo "  --dry-run       仅模拟执行，不实际修改"
    echo "  --push          完成后自动推送到远程"
    echo "  --help, -h      显示此帮助信息"
    echo ""
    echo "分支文件格式示例 (branches.txt):"
    echo "  master"
    echo "  development"
    echo "  release/25w14"
    echo ""
    echo "示例:"
    echo "  $0 git@github.com:user/repo.git branches.txt --dry-run"
    echo "  $0 git@github.com:user/repo.git branches.txt --push"
}

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    local missing=()

    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi

    if ! command -v git-lfs &> /dev/null; then
        missing+=("git-lfs")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        log_error "缺少以下依赖: ${missing[*]}"
        log_info "请先安装缺失的依赖项"
        exit 1
    fi
}

# 清理工作目录
cleanup() {
    if [ -d "$WORK_DIR" ]; then
        log_info "清理工作目录: $WORK_DIR"
        rm -rf "$WORK_DIR"
    fi
}

# 处理单个分支
process_branch() {
    local branch=$1
    local local_branch="lfs-config-$branch-$(date +%Y%m%d%H%M%S)"

    log_info "处理分支: ${YELLOW}$branch${NC}"

    # 检查远程分支是否存在
    if ! git ls-remote --heads origin "$branch" | grep -q "$branch"; then
        log_warning "远程分支 '$branch' 不存在，跳过"
        return 1
    fi

    # 获取远程分支
    log_info "  获取远程分支..."
    git fetch origin "$branch" 2>/dev/null || {
        log_error "  获取分支失败: $branch"
        return 1
    }

    # 创建本地工作分支
    log_info "  创建工作分支: $local_branch"
    git checkout -b "$local_branch" "origin/$branch" 2>/dev/null || {
        log_error "  创建工作分支失败"
        return 1
    }

    # 检查是否已存在 .gitattributes
    if [ -f "$LFS_ATTRIBUTES_FILE" ]; then
        log_warning "  分支已存在 .gitattributes 文件"
        if [ "$DRY_RUN" = false ]; then
            read -p "  是否覆盖? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "  跳过此分支"
                git checkout "$branch" 2>/dev/null || true
                git branch -D "$local_branch" 2>/dev/null || true
                return 0
            fi
        fi
    fi

    # 写入 LFS 配置
    if [ "$DRY_RUN" = true ]; then
        log_info "  [DRY-RUN] 将写入 .gitattributes 文件"
    else
        log_info "  写入 .gitattributes 文件..."
        echo "$LFS_CONFIG" > "$LFS_ATTRIBUTES_FILE"
    fi

    # 暂存文件
    if [ "$DRY_RUN" = true ]; then
        log_info "  [DRY-RUN] 将暂存文件: git add .gitattributes"
    else
        git add "$LFS_ATTRIBUTES_FILE"
    fi

    # 创建提交
    if [ "$DRY_RUN" = true ]; then
        log_info "  [DRY-RUN] 将创建提交"
    else
        log_info "  创建提交..."
        git commit -m "$COMMIT_MSG" || {
            log_warning "  没有变更需要提交（可能文件已存在且内容相同）"
        }
    fi

    # 推送变更
    if [ "$PUSH_CHANGES" = true ] && [ "$DRY_RUN" = false ]; then
        log_info "  推送到远程..."
        if git push origin "$local_branch:$branch" 2>/dev/null; then
            log_success "  推送成功: $branch"
        else
            log_error "  推送失败: $branch"
            return 1
        fi
    fi

    # 切回原分支并清理
    git checkout - 2>/dev/null || true
    git branch -D "$local_branch" 2>/dev/null || true

    log_success "  完成: $branch"
    return 0
}

# 主函数
main() {
    local repo_url=""
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
                if [ -z "$repo_url" ]; then
                    repo_url="$1"
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
    if [ -z "$repo_url" ] || [ -z "$branches_file" ]; then
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

    # 创建工作目录
    log_info "创建工作目录: $WORK_DIR"
    mkdir -p "$WORK_DIR"

    # 克隆仓库
    log_info "克隆仓库: $repo_url"
    git clone --no-single-branch "$repo_url" "$WORK_DIR/repo" || {
        log_error "克隆仓库失败"
        exit 1
    }

    cd "$WORK_DIR/repo"

    # 初始化 Git LFS
    log_info "初始化 Git LFS..."
    git lfs install

    # 读取分支列表
    local branches=()
    while IFS= read -r line || [ -n "$line" ]; do
        # 跳过空行和注释
        line=$(echo "$line" | xargs)
        if [ -n "$line" ] && [[ ! "$line" =~ ^# ]]; then
            branches+=("$line")
        fi
    done < "$branches_file"

    log_info "找到 ${#branches[@]} 个分支需要处理"
    echo ""

    # 显示模式
    if [ "$DRY_RUN" = true ]; then
        log_warning "运行模式: 模拟执行 (DRY-RUN)"
    else
        log_info "运行模式: 实际执行"
    fi

    if [ "$PUSH_CHANGES" = true ]; then
        log_warning "将在完成后自动推送到远程"
    fi

    echo ""
    log_info "=========================================="
    log_info "开始处理分支..."
    log_info "=========================================="
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
    log_info "=========================================="
    log_info "处理完成"
    log_info "=========================================="
    log_success "成功: $success_count"
    if [ $fail_count -gt 0 ]; then
        log_error "失败: $fail_count"
    fi

    if [ "$DRY_RUN" = true ]; then
        log_warning "这是模拟执行，未实际修改任何内容"
        log_info "移除 --dry-run 参数以实际执行"
    fi

    if [ "$PUSH_CHANGES" = false ] && [ "$DRY_RUN" = false ]; then
        log_info "变更已提交到本地，使用 --push 参数自动推送"
    fi
}

# 执行主函数
main "$@"
