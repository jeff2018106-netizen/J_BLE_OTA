# esp-ble-ota-ios

ESP32 BLE OTA iOS客户端应用

## 📱 应用功能

- 蓝牙BLE设备固件升级（OTA）
- 支持ESP32系列芯片
- 自动发现和连接设备
- 实时进度显示

## 🚀 快速开始（云端编译）

### Windows用户推荐方案

由于iOS应用必须在macOS上编译，我们已为你配置好**GitHub Actions自动化编译**：

#### ✅ 已完成的配置
- [x] GitHub Actions工作流 (`.github/workflows/ios-build.yml`)
- [x] 完整的编译指南 (`IOS_BUILD_GUIDE.md`)
- [x] 快速启动工具 (`quick_start.bat`)

### 5分钟快速上手

1. **运行快速启动工具**:
   ```bash
   double-click quick_start.bat
   ```

2. **准备Apple开发者证书**（需要Apple Developer账号 $99/年）:
   - 创建开发证书 (.p12)
   - 创建描述文件 (.mobileprovision)
   
3. **上传到GitHub并配置Secrets**:
   - Fork本仓库到你的GitHub账号
   - 配置5个必要的Secrets（详见 `IOS_BUILD_GUIDE.md`）
   
4. **触发自动编译**:
   - 进入Actions页面手动触发，或推送代码自动触发
   
5. **下载IPA安装包**:
   - 编译完成后在Artifacts中下载 `.ipa` 文件
   - 使用AltStore等工具安装到iPhone

### 详细文档

📖 **完整指南**: 查看 [`IOS_BUILD_GUIDE.md`](./IOS_BUILD_GUIDE.md)  
🛠️ **快速工具**: 运行 [`quick_start.bat`](./quick_start.bat)  
⚙️ **工作流配置**: 查看 [`.github/workflows/ios-build.yml`](./.github/workflows/ios-build.yml)

---

## 📲 传统方式导入升级文件

手机需要接入到电脑端， 然后将对应的升级固件拖入到 app 下面，mac 端找到手机 --> esp-ble-ota --> 文件 --> 拖入要升级的文件。

## 🔧 开发环境要求

### 必需工具
- **Xcode 14+** (仅macOS)
- **CocoaPods** (依赖管理)
- **iOS 13.0+** SDK

### 本地开发（Mac用户）

```bash
# 克隆项目
git clone https://github.com/EspressifApps/esp-ble-ota-ios.git
cd esp-ble-ota-ios/esp-ble-ota

# 安装依赖
pod install

# 打开Xcode workspace
open esp-ble-ota.xcworkspace
```

## 📊 支持的云端编译平台

| 平台 | 免费额度 | 推荐度 | 配置难度 |
|------|---------|--------|---------|
| **GitHub Actions** ⭐ | 2000分钟/月 | ⭐⭐⭐⭐⭐ | 中等 |
| App Center | 无限免费 | ⭐⭐⭐⭐ | 较高 |
| Codemagic | 500分钟/月 | ⭐⭐⭐⭐ | 简单 |
| Bitrise | 45分钟/天 | ⭐⭐⭐ | 中等 |

详细对比请查看: [`IOS_BUILD_GUIDE.md`](./IOS_BUILD_GUIDE.md) #云端编译方案对比

## 🤝 协议一致性说明

### Android vs iOS 协议差异

本项目与Android版本 ([Dial_XEO_202_Android_APP](../Dial_XEO_202_Android_APP)) 的主要差异：

#### START命令字段对比
| 字段 | Android | iOS | 影响 |
|------|---------|-----|------|
| binSize (4字节) | ✅ | ✅ | 一致 |
| upgradeType | ✅ | ❌ | iOS暂不支持差分升级 |
| partitionNumber | ✅ | ❌ | iOS暂不支持多分区 |
| isDeltaUpgrade | ✅ | ❌ | 同上 |
| 其他扩展字段 | ✅ | ❌ | 高级功能受限 |

**结论**: 基本的全量升级功能完全兼容，高级功能需要后续同步。

详见: [`BleOTAUtils.m`](esp-ble-ota/ESPOTATool/BleOTAUtils.m) 第55-60行

## 📝 许可证

[License](LICENSE)