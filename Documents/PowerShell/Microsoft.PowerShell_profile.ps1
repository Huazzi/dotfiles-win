[System.Console]::OutputEncoding=[System.Text.Encoding]::GetEncoding(65001) # 配置默认编码

# 配置oh-my-posh的theme
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\kali.omp.json" | Invoke-Expression

# 使用自定义主题
oh-my-posh init pwsh --config ~/.mytheme.omp.json | Invoke-Expression

#------------------------------- Import Modules BEGIN -------------------------------
# 引入 ps-read-line
Import-Module PSReadLine
 
# 引入 posh-git
Import-Module posh-git
 
# 引入 oh-my-posh —>更新：删除导入
# Import-Module oh-my-posh
 
# 设置 PowerShell 主题 —> 更新：删除
# Set-PoshPrompt ys
# Set-PoshPrompt cinnamon
#------------------------------- Import Modules END   -------------------------------
 
#-------------------------------  Set Hot-keys BEGIN  -------------------------------
# 设置预测文本来源为历史记录
Set-PSReadLineOption -PredictionSource History
 
# 每次回溯输入历史，光标定位于输入内容末尾
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
 
# 设置 Tab 为菜单补全和 Intellisense
Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
 
# 设置 Ctrl+d 为退出 PowerShell
Set-PSReadlineKeyHandler -Key "Ctrl+d" -Function ViExit
 
# 设置 Ctrl+z 为撤销
Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo
 
# 设置向上键为后向搜索历史记录
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
 
# 设置向下键为前向搜索历史纪录
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
#-------------------------------  Set Hot-keys END    -------------------------------

# 设置scoop安装路径
$env:SCOOP = 'D:\Applications\ScoopApps'
