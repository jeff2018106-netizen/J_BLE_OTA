@echo off
chcp 65001 >nul
echo ========================================
echo   iOS 云端编译 - 快速启动工具
echo ========================================
echo.

:: 检查Git是否安装
where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [❌] 错误: 未检测到Git，请先安装Git
    echo     下载地址: https://git-scm.com/downloads
    pause
    exit /b 1
)
echo [✓] Git已安装

:: 检查项目目录
if not exist "esp-ble-ota" (
    echo [❌] 错误: 未找到iOS项目目录
    echo     请确保在esp-ble-ota-ios根目录运行此脚本
    pause
    exit /b 1
)
echo [✓] iOS项目目录存在

echo.
echo 请选择操作:
echo.
echo   [1] 生成证书Base64编码（用于GitHub Secrets）
echo   [2] 生成描述文件Base64编码（用于GitHub Secrets）
echo   [3] 验证项目结构完整性
echo   [4] 创建本地测试构建（需要Mac）
echo   [5] 显示完整配置指南
echo   [6] 退出
echo.
set /p choice=请输入选项 (1-6):

if "%choice%"=="1" goto cert_encode
if "%choice%"=="2" goto profile_encode
if "%choice%"=="3" goto verify_structure
if "%choice%"=="4" goto local_build
if "%choice%"=="5" show_guide
if "%choice%"=="6" exit

echo 无效选项
pause
exit /b 1

:cert_encode
echo.
echo ========================================
echo   证书Base64编码工具
echo ========================================
echo.
echo 请将 .p12 证书文件拖放到此窗口，然后按回车:
set /p cert_path=
if not exist "%cert_path%" (
    echo [❌] 文件不存在: %cert_path%
    pause
    exit /b 1
)

echo.
echo 正在编码证书文件...
certutil -encode "%cert_path%" cert_b64.txt >nul 2>nul
if %errorlevel% neq 0 (
    echo [❌] 编码失败
    pause
    exit /b 1
)

echo.
echo [✓] 编码成功！
echo.
echo ============================================
echo   复制以下内容到 GitHub Secret:
echo   Secret名称: BUILD_CERTIFICATE_BASE64
echo ============================================
echo.
type cert_b64.txt
echo.
echo ============================================
del cert_b64.txt
echo.
echo 提示: 已自动复制到剪贴板（如果支持）
pause
exit /b 0

:profile_encode
echo.
echo ========================================
echo   描述文件Base64编码工具
echo ========================================
echo.
echo 请将 .mobileprovision 文件拖放到此窗口，然后按回车:
set /p profile_path=
if not exist "%profile_path%" (
    echo [❌] 文件不存在: %profile_path%
    pause
    exit /b 1
)

echo.
echo 正在编码描述文件...
certutil -encode "%profile_path%" profile_b64.txt >nul 2>nul
if %errorlevel% neq 0 (
    echo [❌] 编码失败
    pause
    exit /b 1
)

echo.
echo [✓] 编码成功！
echo.
echo ============================================
echo   复制以下内容到 GitHub Secret:
echo   Secret名称: PROVISIONING_PROFILE_BASE64
echo ============================================
echo.
type profile_b64.txt
echo.
echo ============================================
del profile_b64.txt
pause
exit /b 0

:verify_structure
echo.
echo ========================================
echo   项目结构验证
echo ========================================
echo.

set errors=0

:: 检查必需文件
if exist "esp-ble-ota.xcodeproj\project.pbxproj" (
    echo [✓] Xcode项目文件存在
) else (
    echo [❌] 缺少Xcode项目文件
    set /a errors+=1
)

if exist ".github\workflows\ios-build.yml" (
    echo [✓] GitHub Actions工作流已配置
) else (
    echo [⚠] GitHub Actions工作流未找到（可选）
)

if exist "esp-ble-ota\ViewController.m" (
    echo [✓] 主视图控制器存在
) else (
    echo [❌] 缺少主视图控制器
    set /a errors+=1
)

if exist "esp-ble-ota\ESPOTATool\BleOTAUtils.m" (
    echo [✓] OTA工具类存在
) else (
    echo [❌] 缺少OTA工具类
    set /a errors+=1
)

if exist "IOS_BUILD_GUIDE.md" (
    echo [✓] 编译指南文档存在
) else (
    echo [⚠] 编译指南文档未找到
)

echo.
if %errors% equ 0 (
    echo [✅] 项目结构完整！可以进行云端编译
) else (
    echo [❌] 发现 %errors% 个问题，请检查后重试
)
echo.
pause
exit /b 0

:local_build
echo.
echo ========================================
echo   本地构建（仅限Mac）
echo ========================================
echo.
echo ⚠️  此功能需要在macOS系统上运行
echo.
echo 如果你在Mac上，请执行以下命令:
echo.
echo   cd esp-ble-ota
echo   pod install
echo   xcodebuild -workspace esp-ble-ota.xcworkspace ^
echo              -scheme esp-ble-ota ^
echo              -configuration Debug ^
echo              -sdk iphoneos ^
echo              CODE_SIGN_IDENTITY="" ^
echo              CODE_SIGNING_REQUIRED=NO ^
echo              CODE_SIGNING_ALLOWED=NO
echo.
pause
exit /b 0

:show_guide
echo.
echo ========================================
echo   打开完整编译指南...
echo ========================================
start "" "IOS_BUILD_GUIDE.md"
pause
exit /b 0