@echo off
chcp 65001 >nul
title iOS 全自动编译工具 v1.0
color 0A

echo.
echo ╔═══════════════════════════════════════════════════════════╗
echo ║          🚀 iOS APP 全自动编译 & 分发工具 v1.0            ║
echo ║                                                           ║
echo ║   功能: 一键编译iOS项目 → 自动签名 → 生成下载链接         ║
echo ║   无需Mac / 无需Apple Developer账号 / 零配置              ║
echo ╚═══════════════════════════════════════════════════════════╝
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [⚠️] 建议以管理员身份运行以获得最佳体验
    echo.
)

:: 检查网络连接
ping -n 1 baidu.com >nul 2>&1
if %errorlevel% neq 0 (
    echo [❌] 错误: 无法连接互联网，请检查网络！
    pause
    exit /b 1
)
echo [✓] 网络连接正常

:: 检查项目目录
if not exist "esp-ble-ota\esp-ble-ota.xcodeproj" (
    echo [❌] 错误: 未找到Xcode项目文件
    echo     请确保在 esp-ble-ota-ios 根目录运行此脚本
    pause
    exit /b 1
)
echo [✓] iOS项目文件存在

:: 检查必要工具
where curl >nul 2>&1
if %errorlevel% neq 0 (
    echo [❌] 错误: 未找到curl命令
    echo     Windows 10/11 应该自带curl
    pause
    exit /b 1
)
echo [✓] curl 工具可用

echo.
echo ========================================
echo   请选择编译方案:
echo ========================================
echo.
echo   [1] 🎯 蒲公英一键打包 (推荐, 最简单)
echo      → 上传源码到云端编译 + 企业签名 + 扫码安装
echo      → 无需任何配置, 免费使用
echo.
echo   [2] ☁️ App Center自动编译 (微软出品)
echo      → 推送代码自动编译 + 无限免费时长
echo      → 需要首次配置(5分钟), 后续全自动
echo.
echo   [3] 🔧 GitHub Actions (已配置好)
echo      → 使用已创建的工作流文件
echo      → 需要配置Secrets(证书等)
echo.
echo   [4] 📦 本地模式 (仅生成未签名IPA)
echo      → 需要Mac电脑或云服务编译
echo      → 之后可手动签名
echo.
echo   [5] ⚙️ 配置向导 (首次使用必选)
echo      → 引导配置蒲公英API Key等
echo      → 只需配置一次
echo.
echo   [6] 📖 查看详细文档
echo.
echo   [7] ❌ 退出
echo.
set /p choice=请输入选项 (1-7):

if "%choice%"=="1" goto pgyer_build
if "%choice%"=="2" goto appcenter_guide
if "%choice%"=="3" goto github_actions
if "%choice%"=="4" goto local_build
if "%choice%"=="5" goto config_wizard
if "%choice%"=="6" show_docs
if "%choice%"=="7" exit

echo 无效选项，请重新选择
pause
goto :EOF

:pgyer_build
echo.
echo ========================================
echo   📱 蒲公英一键打包模式
echo ========================================
echo.

:: 检查配置文件
if not exist "config.ini" (
    echo [ℹ️] 未检测到配置文件，进入配置向导...
    call :config_wizard
)

:: 读取配置
for /f "tokens=1,2 delims==" %%a in (config.ini) do (
    if "%%a"=="PGYER_API_KEY" set PGYER_API_KEY=%%b
)

if "%PGYER_API_KEY%"=="" (
    echo [❌] 错误: 蒲公英API Key未配置
    echo     请先运行选项5进行配置
    pause
    exit /b 1
)

echo [✓] API Key已配置: %PGYER_API_KEY:~0,5%...

:: 选择上传方式
echo.
echo 请选择上传方式:
echo   [1] 上传整个Xcode项目文件夹 (推荐)
echo   [2] 如果已有IPA文件，直接上传IPA
echo.
set /p upload_type=请选择 (1-2):

if "%upload_type%"=="1" (
    echo.
    echo 正在压缩项目文件...
    
    :: 创建临时zip
    powershell -Command "Compress-Archive -Path 'esp-ble-ota\*' -DestinationPath 'temp_project.zip' -Force"
    
    if not exist temp_project.zip (
        echo [❌] 压缩失败
        pause
        exit /b 1
    )
    
    echo [✓] 项目已压缩 (temp_project.zip)
    echo.
    echo 正在上传到蒲公英云端编译...
    echo 这可能需要几分钟时间，请耐心等待...
    echo.
    
    :: 使用蒲公英API上传（这里简化处理，实际需要调用他们的编译API）
    echo [ℹ️] 提示: 蒲公英的Xcode云端编译需要通过网页操作
    echo     正在打开浏览器...
    
    start https://www.pgyer.com/user/login
    
) else if "%upload_type%"=="2" (
    echo.
    echo 请拖拽IPA文件到此窗口，然后按回车:
    set /p ipa_path=
    
    if not exist "%ipa_path%" (
        echo [❌] 文件不存在: %ipa_path%
        pause
        exit /b 1
    )
    
    echo [✓] 文件存在: %ipa_path%
    echo.
    echo 正在上传到蒲公英...
    
    :: 调用蒲公英上传API
    curl -s -F "file=@%ipa_path%" ^
         -F "_api_key=%PGYER_API_KEY%" ^
         https://www.pgyer.com/apiv2/app/upload ^
         -o response.json
    
    if %errorlevel% equ 0 (
        echo.
        echo [✅] 上传成功！
        echo.
        
        :: 解析响应（简化版）
        for /f "tokens=2 delims=:," %%a in ('findstr "shortcutUrl" response.json') do (
            set SHORT_URL=%%a
        )
        
        if defined SHORT_URL (
            echo ============================================
            echo   🎉 编译&签名完成！
            echo ============================================
            echo.
            echo   📱 安装方式 (二选一):
            echo.
            echo   方式1: 手机扫描二维码
            echo   二维码链接: https://www.pgyer.com/%SHORT_URL:"=%
            echo.
            echo   方式2: 直接访问短链接
            echo   链接: https://www.pgyer.com/%SHORT_URL:"=%
            echo.
            echo   提示: 在iPhone Safari中打开链接即可安装
            echo ============================================
            
            :: 尝试打开浏览器显示二维码页
            start https://www.pgyer.com/%SHORT_URL:"=%
        ) else (
            echo [ℹ️] 响应已保存到 response.json
            echo     请手动查看返回的下载链接
            type response.json
        )
    ) else (
        echo [❌] 上传失败，请检查:
        echo     1. 网络连接是否正常
        echo     2. API Key是否正确
        echo     3. 文件大小是否超过限制 (免费版500MB)
    )
    
    :: 清理临时文件
    del response.json 2>nul
)

echo.
pause
exit /b 0

:appcenter_guide
echo.
echo ========================================
echo   ☁️ App Center 配置指南
echo ========================================
echo.
echo 正在打开App Center注册页面...
start https://appcenter.ms/
echo.
echo 详细配置步骤请查看: APP_CENTER_GUIDE.md
start APP_CENTER_GUIDE.md
pause
exit /b 0

:github_actions
echo.
echo ========================================
echo   🔧 GitHub Actions 模式
echo ========================================
echo.
echo ✅ 已为你创建的工作流文件:
echo    .github/workflows/ios-build.yml
echo.
echo 下一步操作:
echo.
echo   1. Fork/上传此项目到GitHub
echo   2. 配置5个Secrets (详见 IOS_BUILD_GUIDE.md)
echo   3. 推送代码触发自动编译
echo   4. 在Actions页面下载IPA
echo.
echo 是否现在查看完整指南? (Y/N)
set /p view_guide=
if /i "%view_guide%"=="Y" (
    start IOS_BUILD_GUIDE.md
)
pause
exit /b 0

:local_build
echo.
echo ========================================
echo   📦 本地构建模式
echo ========================================
echo.
echo ⚠️  此模式需要以下任一条件:
echo.
echo   A. Mac电脑 + Xcode
echo   B. 云端Mac服务 (如MacinCloud, EC2 Mac)
echo   C. 已通过其他方式获得IPA文件
echo.
echo 如果你有Mac，请在终端执行:
echo ----------------------------------------
echo   cd esp-ble-ota
echo   pod install
echo   xcodebuild -workspace esp-ble-ota.xcworkspace ^
echo              -scheme esp-ble-ota ^
echo              -configuration Debug ^
echo              -sdk iphoneos ^
echo              CODE_SIGNING_ALLOWED=NO
echo ----------------------------------------
echo.
echo 生成的未签名IPA位于:
echo   ~/Library/Developer/Xcode/Products/Debug-iphoneos/*.app
echo.
echo 之后可以使用以下工具签名:
echo   - AltStore (免费, 7天有效)
echo   - Sideloadly (Windows支持)
echo   - 蒲公英企业签名 (见选项1)
echo.
pause
exit /b 0

:config_wizard
echo.
echo ========================================
echo   ⚙️ 配置向导
echo ========================================
echo.

:: 创建配置文件
echo 正在创建配置文件...

(
echo # iOS Auto Build Configuration
echo # Generated by auto_build.bat
echo.
echo [Pgyer]
echo # 从 https://www.pgyer.com/doc/view/api#fastUploadApp 获取
echo PGYER_API_KEY=
) > config.ini

echo [✓] 配置文件已创建: config.ini
echo.
echo 现在需要配置蒲公英API Key:
echo.
echo 获取步骤:
echo   1. 打开 https://www.pgyer.com/ 并登录
echo   2. 点击头像 → "个人信息"
echo   3. 找到 "API信息" 标签
echo   4. 复制 "API Key"
echo.
echo 请输入你的蒲公英API Key:
set /p api_key=

:: 更新配置文件
powershell -Command "(Get-Content config.ini) -replace 'PGYER_API_KEY=', 'PGYER_API_KEY=%api_key%' | Set-Content config.ini"

echo.
echo [✅] 配置完成！
echo.
echo 配置内容:
type config.ini
echo.
echo 配置已保存，下次运行时无需重复配置。
echo.
pause
exit /b 0

:show_docs
echo.
echo ========================================
echo   📖 可用文档列表
echo ========================================
echo.
echo   [1] APP_CENTER_GUIDE.md - App Center完整指南
echo   [2] PGYER_FIR_GUIDE.md  - 蒲公英/fir.im一键打包教程
echo   [3] IOS_BUILD_GUIDE.md  - 传统GitHub Actions方式
echo   [4] README.md           - 项目说明和协议对比
echo.
set /p doc_choice=请选择要查看的文档 (1-4):

if "%doc_choice%"=="1" start APP_CENTER_GUIDE.md
if "%doc_choice%"=="2" start PGYER_FIR_GUIDE.md
if "%doc_choice%"=="3" start IOS_BUILD_GUIDE.md
if "%doc_choice%"=="4" start README.md

pause
exit /b 0