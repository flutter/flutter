@echo off
setlocal enabledelayedexpansion

rem 当前执行：移除原http远程仓库
git remote remove upstream 2>nul || echo remote upstream not found...

rem 当前执行：添加ssh格式的上游仓库（原仓库）
git remote add upstream git@github.com:flutter/flutter.git

rem 当前执行：添加ssh格式的个人fork仓库
git remote set-url origin git@github.com:bravestarrhu/flutter.git

rem 当前执行：从上游仓库重新拉取标签
git fetch upstream --tags

rem 当前执行：将标签推送到个人fork仓库
git push origin --tags

rem 当前执行：拉取上游更新
git fetch upstream

rem 当前执行：切换到主分支并合并更新并推送到个人fork仓库
git checkout master
git merge upstream/master
git push origin master

rem 当前执行：切换到 beta 分支并合并更新并推送到个人fork仓库
git checkout beta
git merge upstream/beta
git push origin beta

rem 当前执行：切换到 stable 分支并合并更新并推送到个人fork仓库
git checkout stable
git merge upstream/stable
git push origin stable

rem 同步完成！
pause