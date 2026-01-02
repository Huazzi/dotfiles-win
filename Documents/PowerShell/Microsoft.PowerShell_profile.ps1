# ------------------------------- 1. 配置默认编码 -------------------------------
[System.Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding(65001)

# ------------------------------- 2. 只有在交互式界面才加载 UI 相关配置 -------------------------------
if ($Host.Name -eq 'ConsoleHost' -or $Host.Name -eq 'Windows Terminal') {

    #------------------------------- Import Modules -------------------------------
    # 仅保留核心的补全插件，移除 posh-git 和 oh-my-posh
    Import-Module PSReadLine
	
	# --- 自定义 Banner 函数 ---
    function Show-CustomBanner {
        $logo = @"
    ██████╗  ██████╗ ██╗    ██╗███████╗██████╗ ███████╗██╗  ██╗███████╗██╗     ██╗     
    ██╔══██╗██╔═══██╗██║    ██║██╔════╝██╔══██╗██╔════╝██║  ██║██╔════╝██║     ██║     
    ██████╔╝██║   ██║██║ █╗ ██║█████╗  ██████╔╝███████╗███████║█████╗  ██║     ██║     
    ██╔═══╝ ██║   ██║██║███╗██║██╔══╝  ██╔══██╗╚════██║██╔══██║██╔══╝  ██║     ██║     
    ██║     ╚██████╔╝╚███╔███╔╝███████╗██║  ██║███████║██║  ██║███████╗███████╗███████╗
    ╚═╝      ╚═════╝  ╚══╝╚══╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
"@
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $cyan="`e[36m"; $gray="`e[90m"; $purple="`e[35m"; $yellow="`e[33m"; $blue="`e[34m"; $reset="`e[0m"
        
        Write-Host "$cyan$logo$reset"
        Write-Host "    User: $purple$env:USERNAME@$env:COMPUTERNAME$reset"
        Write-Host "    Time: $yellow$time$reset"
        Write-Host "    $blue---------------------------------------$reset"
    }

    # 执行 Banner
    Show-CustomBanner
 
    #------------------------------- Set Hot-keys -------------------------------
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineOption -Colors @{ InlinePrediction = '#808080'} # 预测文本颜色
    
    Set-PSReadLineKeyHandler -Key "Tab" -Function MenuComplete
    Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function ViExit
    Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
	
    #------------------------------- Native Prompt (支持 Mamba/Conda) -------------------------------
    function prompt {
		# 颜色定义
		$pathCol   = "`e[38;2;0;175;255m"  # #00AFFF
		$gitCol    = "`e[38;2;255;231;0m"  # #FFE700
		$symbolCol = "`e[38;2;67;212;38m"  # #43D426
		$condaCol  = "`e[38;2;68;204;136m" # #44CC88 (conda 环境颜色)
		$reset     = "`e[0m"

		# 检测 conda/mamba 环境
		$condaEnv = ""
		if ($env:CONDA_DEFAULT_ENV) {
			$condaEnv = "($env:CONDA_DEFAULT_ENV) "
		}

		# 原生获取 Git 分支名
		$gitBranch = ""
		if (Get-Command git -ErrorAction SilentlyContinue) {
			$gitBranch = git branch --show-current 2>$null
		}

		# 第一行：[conda环境] 路径 [Git分支]
		$currentPath = $ExecutionContext.SessionState.Path.CurrentLocation
    
		# 组合输出
		$line1 = ""
		if ($condaEnv) {
			$line1 += "$condaCol$condaEnv$reset"
		}
		$line1 += "$pathCol$currentPath$reset"
		if ($gitBranch) {
			$line1 += " $gitCol$gitBranch$reset"
		}
    
		Write-Host $line1

		# 第二行：提示符符号
		Write-Host "$symbolCol❯$reset" -NoNewline
    
		return " "
	}
}

# ------------------------------- 3. 环境变量 -------------------------------
$env:SCOOP = 'D:\Applications\ScoopApps'

# npm 全局可执行文件路径
$npmGlobalPath = "D:\DevFile\nodejs\npm_global"
if ($env:PATH -notlike "*$npmGlobalPath*") {
    $env:PATH = "$npmGlobalPath;" + $env:PATH
}

# Node.js 模块查找路径
$env:NODE_PATH = "D:\DevFile\nodejs\npm_global\node_modules"

# ------------------------------- 4. Alias & Custom Functions -------------------------------
Set-Alias -Name vi -Value vim
Set-Alias -Name find -Value where.exe
Set-Alias -Name grep -Value Select-String
Set-Alias -Name np+ -Value D:\Applications\Notepad++\notepad++.exe

# 目录导航
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function home { Set-Location ~ }
function docs { Set-Location ~\Documents }
function dl { Set-Location ~\Downloads }

# 配置文件管理
function edit-profile { D:\Applications\Notepad++\notepad++.exe $PROFILE }
function reload-profile { & $PROFILE }
function test-profile {
    $errors = $null
    $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $PROFILE -Raw), [ref]$errors)
    if ($errors.Count -eq 0) {
        Write-Host "✅ 配置文件语法正确" -ForegroundColor Green
    } else {
        Write-Host "❌ 配置文件语法错误：" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
    }
}

# 文件列表 
# 保留原生 ls
#function ll { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
#function la { Get-ChildItem -Path . -Force -Attributes Hidden,ReadOnly,System }
#function ls { Get-ChildItem @args } 
# eza 替换
# ===== eza 配置 =====
if (Get-Command eza -ErrorAction SilentlyContinue) {
    # 创建基础 eza 命令生成器
    function Get-EzaCommand {
        param(
            [string[]]$ExtraArgs = @(),
            [switch]$Long,
            [switch]$All,
            [switch]$Icons,
            [switch]$Tree,
            [int]$TreeLevel = 2
        )
        
        # 基础参数
        $baseArgs = @(
            "--color=always",
            "--group-directories-first",
            "--time-style=long-iso"
        )
        
        # 添加 Git 状态（如果当前目录是 Git 仓库）
        try {
            $isGitRepo = (git rev-parse --is-inside-work-tree 2>$null) -eq "true"
            if ($isGitRepo) {
                $baseArgs += "--git"
            }
        } catch {}
        
        # 添加额外参数
        if ($Long) { $baseArgs += "-l", "-h" }
        if ($All) { $baseArgs += "-a" }
        if ($Icons) { $baseArgs += "--icons" }
        if ($Tree) { $baseArgs += "--tree", "--level=$TreeLevel" }
        
        # 返回参数数组
        return ($baseArgs + $ExtraArgs)
    }
    
    # 重新定义主要命令
    function ls {
        param([Parameter(ValueFromRemainingArguments)]$ExtraArgs)
        eza @(Get-EzaCommand) @ExtraArgs
    }
    
    function ll {
        param([Parameter(ValueFromRemainingArguments)]$ExtraArgs)
        eza @(Get-EzaCommand -Long) @ExtraArgs
    }
    
    function la {
        param([Parameter(ValueFromRemainingArguments)]$ExtraArgs)
        eza @(Get-EzaCommand -Long -All) @ExtraArgs
    }
    
    function lli {
        param([Parameter(ValueFromRemainingArguments)]$ExtraArgs)
        eza @(Get-EzaCommand -Long -Icons) @ExtraArgs
    }
    
    function tree {
        param(
            [int]$Level = 2,
            [Parameter(ValueFromRemainingArguments)]$ExtraArgs
        )
        eza @(Get-EzaCommand -Tree -TreeLevel $Level) @ExtraArgs
    }
    
    # 按文件大小排序（大文件在前）
    function largest {
        param([Parameter(ValueFromRemainingArguments)]$ExtraArgs)
        eza @(Get-EzaCommand -Long -ExtraArgs @("--sort=size", "--reverse")) @ExtraArgs
    }
    
    # 最新修改的文件
    function latest {
        param([Parameter(ValueFromRemainingArguments)]$ExtraArgs)
        eza @(Get-EzaCommand -Long -ExtraArgs @("--sort=modified", "--reverse")) @ExtraArgs
    }
    
    # 只显示目录
    function dirs {
        param([Parameter(ValueFromRemainingArguments)]$ExtraArgs)
        eza @(Get-EzaCommand -ExtraArgs @("--only-dirs")) @ExtraArgs
    }
}


# 文件操作
function cat { Get-Content @args }
function tail { Get-Content @args -Tail 20 }

# uv pip 快捷命令
function up {
    param([Parameter(ValueFromRemainingArguments)][string[]]$Packages)
    if (-not $Packages) {
        Write-Host "Usage: up <package-name>" -ForegroundColor Yellow
        Write-Host "Example: up requests numpy pandas" -ForegroundColor Cyan
        return
    }
    uv pip install @Packages
}

# 历史命令
function gh { Get-History | Select-String $args }

# 进程管理
function pskill { Get-Process @args -ErrorAction SilentlyContinue | Stop-Process -Force }

# 系统信息
function sysinfo {
    Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, OSArchitecture, CsTotalPhysicalMemory
}
function psver {
    $PSVersionTable.PSVersion
    Write-Host "PowerShell 配置加载完成！" -ForegroundColor Green
}

# Git
if (Get-Command git -ErrorAction SilentlyContinue) {
    function gs { git status }
    function ga { git add . }
    function gc { git commit -m $args }
    function gp { git push }
    function gl { git log --oneline -10 }
}
