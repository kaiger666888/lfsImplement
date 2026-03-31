# Git LFS 批量分支配置工具

## 功能

为指定 Git 仓库的多个分支自动添加 `.gitattributes` 配置，启用 Git LFS 跟踪大文件。

**特点：**
- 只影响未来提交，不修改历史
- 支持批量处理多个分支
- 支持 dry-run 模式预览
- 可选择自动推送到远程

## 使用方法

### 1. 准备分支列表文件

创建一个文本文件，每行一个分支名：

```txt
# branches.txt
master
development
release/25w14
```

### 2. 运行脚本

**模拟执行（推荐先运行）：**
```bash
./apply-lfs-to-branches.sh git@github.com:user/repo.git branches.txt --dry-run
```

**实际执行（不推送）：**
```bash
./apply-lfs-to-branches.sh git@github.com:user/repo.git branches.txt
```

**实际执行并推送：**
```bash
./apply-lfs-to-branches.sh git@github.com:user/repo.git branches.txt --push
```

### 3. 参数说明

| 参数 | 说明 |
|------|------|
| `repo_url` | Git 仓库的远程 URL |
| `branches_file` | 包含分支列表的文件 |
| `--dry-run` | 模拟执行，不实际修改 |
| `--push` | 完成后自动推送到远程 |
| `--help` | 显示帮助信息 |

## 示例：Navigation 仓库

### 模拟执行测试
```bash
cd /c/Kais_Projects/Git_Projects/DHU/Git_DHU_Integration/lfsImplement/scripts

./apply-lfs-to-branches.sh \
  ssh://kzhang82@pear-gerrit-ssh.volvocars.biz/InfotainmentAndroidSDK/Navigation \
  branches-navigation.txt \
  --dry-run
```

### 实际执行（仅主分支）
```bash
# 先创建只包含主分支的配置文件
cat > branches-main-only.txt << EOF
master
development
EOF

./apply-lfs-to-branches.sh \
  ssh://kzhang82@pear-gerrit-ssh.volvocars.biz/InfotainmentAndroidSDK/Navigation \
  branches-main-only.txt
```

## 注意事项

1. **权限要求**：需要有仓库的写入权限
2. **推送策略**：建议先不使用 `--push`，手动检查后再推送
3. **冲突处理**：如果分支已有 `.gitattributes`，脚本会询问是否覆盖
4. **工作目录**：脚本会在 `/tmp` 下创建临时目录，完成后自动清理

## 分支策略建议

| 场景 | 建议配置的分支 |
|------|----------------|
| 最小影响 | master, development |
| 常规开发 | master, development, 活跃feature分支 |
| 完整覆盖 | 所有分支 |

## 故障排查

**问题：克隆失败**
- 检查网络连接和 SSH 密钥配置

**问题：推送失败**
- 检查是否有权限推送到目标分支
- 检查是否需要通过 Gerrit review 流程

**问题：分支不存在**
- 确认分支名拼写正确
- 脚本会自动跳过不存在的分支
