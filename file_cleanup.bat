@echo off
setlocal enabledelayedexpansion

:: ========================================================
:: 文件清理自动化脚本 v0.1
:: 功能：仅删除目标文件夹中的文件（保留所有文件夹结构），立即删除所有文件
::       每天生成1个带时间戳的日志文件（格式：YYYY-MM-DD_HH-MM-SS.log）
:: 配置说明：
::   target_folder - 需要清理的目标路径（必填）
::   log_folder    - 日志存放目录（默认当前目录/logs）
:: ========================================================

:: ******************** 用户配置区域 **********************
set "target_folder=D:\Your\Target\Path"  :: 需清理的目标路径 (示例, 请修改为您的实际路径)
set "log_folder=%~dp0logs"               :: 日志存放目录 (默认脚本所在目录下的logs文件夹)
set "log_retention=30"                   :: 日志保留天数 (单位：天)
:: *******************************************************

:: ===== 生成当日日志文件名（格式：YYYY-MM-DD_HH-MM-SS.log） =====
for /f "tokens=1-6 delims=/: " %%a in ('echo %date% %time%') do (
    set "log_date=%%c-%%a-%%b"
    set "log_time=%%d-%%e-%%f"
)
set "log_time=!log_time: =0!"  :: 补全时间前导零（如09:05:03）
set "log_file=%log_folder%\%log_date%_%log_time%.log"

:: ===== 初始化日志系统 =====
if not exist "%log_folder%" mkdir "%log_folder%"
if errorlevel 1 (
    echo [%time%] 错误：无法创建日志目录 "%log_folder%"。请检查权限或路径设置。 >&2
    exit /b 1
)

:: ===== 检查目标文件夹是否存在 =====
if not exist "%target_folder%" (
    call :log "错误：目标文件夹 '%target_folder%' 不存在。脚本将退出。"
    echo [%time%] 错误：目标文件夹 "%target_folder%" 不存在。脚本将退出。 >&2
    exit /b 1
)

:: ===== 记录操作开始 =====
call :log "========== [%date% %time%] 清理操作开始 =========="
call :log "目标路径: %target_folder%"
call :log "清理策略: 删除所有文件（保留文件夹结构）"

:: ===== 核心文件删除逻辑（仅删文件） =====
set "file_count=0"
set "fail_count=0"

:: 遍历目标文件夹所有文件（跳过文件夹）
for /r "%target_folder%" %%f in (*) do (
  if exist "%%f" if not exist "%%f\*" (  :: 检查是否为文件（非文件夹）
    del /f /q "%%f" 2>nul 
    if !errorlevel! equ 0 (
      set /a file_count+=1
      call :log "成功删除文件: %%f"
    ) else (
      set /a fail_count+=1
      call :log "删除失败文件: %%f（权限不足或被占用）"
    )
  )
)

:: ===== 记录操作结果 =====
call :log "========== 操作统计 =========="
call :log "成功删除文件数量: %file_count%"
if %fail_count% gtr 0 call :log "删除失败文件数量: %fail_count%"
call :log "文件夹结构保留完成"
call :log "========== [%date% %time%] 清理操作结束 =========="
call :log ""

:: ===== 清理旧日志 =====
call :log "开始清理旧日志文件，保留最近 %log_retention% 天的日志..."
set "cleaned_log_count=0"
forfiles /P "%log_folder%" /M "*.log" /D -%log_retention% /C "cmd /c del @path && set /a cleaned_log_count+=1 && call :log \"已删除旧日志: @file\""
call :log "共清理旧日志文件数量: !cleaned_log_count!"
call :log "旧日志清理完成。"

endlocal
echo 清理操作完成，详情请查看日志文件: %log_file%
exit /b

:: ===== 日志函数（带时间戳） =====
:log
  echo [%time%] %~1 >> "%log_file%"
  exit /b

:: 说明：
:: 1. for /r 遍历所有文件，if not exist "%%f\*" 确保仅处理文件（跳过文件夹）
:: 2. 日志文件名格式：YYYY-MM-DD_HH-MM-SS.log，每天自动生成独立文件
:: 3. 立即删除所有文件（无时间过滤），仅保留文件夹结构
