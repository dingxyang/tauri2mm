#!/usr/bin/env bash
set -e

echo "========================================"
echo "   Git 提交作者重命名工具"
echo "========================================"
echo

# 检查是否在 git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "[错误] 当前目录不是 git 仓库，请在 git 仓库根目录下运行。"
    exit 1
fi

# 显示当前提交作者列表
echo "当前仓库中的作者："
echo "----------------------------------------"
git log --format="%an <%ae>" | sort -u
echo "----------------------------------------"
echo

# 输入旧名称
read -rp "请输入要替换的旧作者名称: " OLD_NAME
if [ -z "$OLD_NAME" ]; then
    echo "[错误] 旧作者名称不能为空。"
    exit 1
fi

# 输入新名称
read -rp "请输入新的作者名称: " NEW_NAME
if [ -z "$NEW_NAME" ]; then
    echo "[错误] 新作者名称不能为空。"
    exit 1
fi

echo
echo "即将把所有作者名 \"$OLD_NAME\" 替换为 \"$NEW_NAME\""
echo "（邮箱地址保持不变）"
echo
read -rp "确认执行？(y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "已取消。"
    exit 0
fi

echo
echo "[执行中] 正在重写提交历史..."

export FILTER_BRANCH_SQUELCH_WARNING=1

git filter-branch --env-filter "
if [ \"\$GIT_AUTHOR_NAME\" = \"$OLD_NAME\" ]; then
    export GIT_AUTHOR_NAME=\"$NEW_NAME\"
fi
if [ \"\$GIT_COMMITTER_NAME\" = \"$OLD_NAME\" ]; then
    export GIT_COMMITTER_NAME=\"$NEW_NAME\"
fi
" --tag-name-filter cat -- --all

echo
echo "[完成] 提交历史重写成功！"
echo
echo "修改后的提交记录（最近10条）："
echo "----------------------------------------"
git log --format="%h %an <%ae> %s" -10
echo "----------------------------------------"
echo

# 询问是否强制推送
read -rp "是否强制推送到远程仓库？(y/n): " PUSH
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$PUSH" =~ ^[Yy]$ ]]; then
    echo "[执行中] 强制推送分支 $BRANCH 到 origin..."
    if git push origin "$BRANCH" --force; then
        echo "[完成] 推送成功！"
    else
        echo "[错误] 推送失败，请手动执行: git push origin $BRANCH --force"
    fi
else
    echo "如需同步到远程，请手动执行："
    echo "  git push origin $BRANCH --force"
fi

echo
