# App Center 全自动编译指南 (5分钟配置，永久自动)

> **目标**: 推送代码 → 自动编译 → 自动生成IPA → 下载链接通知你  
> **费用**: 完全免费  
> **时间**: 首次配置5分钟，后续每次编译10-15分钟自动完成

---

## 🚀 快速开始（3步搞定）

### 第1步：注册App Center账号（30秒）

1. 打开 https://appcenter.ms/
2. 点击 "Sign up with Microsoft/GitHub/Google账户"
3. 登录后进入Dashboard

---

### 第2步：创建应用并连接Git仓库（2分钟）

#### 2.1 创建新应用
```
点击 "+" → "Add new app" → 
  App name: esp-ble-ota-ios
  OS: iOS
  Platform: Objective-C/Swift
→ 点击 "Add new app"
```

#### 2.2 连接GitHub仓库
```
进入刚创建的应用 → 
点击 "Build" 标签 → 
选择 "GitHub" → 
授权你的GitHub账号 → 
选择 "esp-ble-ota-ios" 仓库 → 
选择 "main" 分支 → 
点击 "Save build configuration"
```

✅ **恭喜！基础连接已完成！**

---

### 第3步：配置编译脚本（2分钟） - ⚠️ 关键步骤

App Center会**自动检测Xcode项目**，但需要你告诉它如何签名：

#### 方式A: 使用App Center自动签名（推荐新手）

在项目根目录创建 `appcenter-post-clone.sh` 文件：

```bash
#!/bin/bash

# App Center自动签名配置
# 此脚本会在每次构建前自动运行

# 安装CocoaPods依赖
cd esp-ble-ota
pod install

echo "✅ 依赖安装完成"
```

**然后上传到GitHub**:
```bash
git add appcenter-post-clone.sh
git commit -m "Add App Center build script"
git push origin main
```

#### 方式B: 手动配置签名（需要Apple Developer账号）

如果你有开发者账号，在App Center的Build设置中：

1. 进入 **Build** → **Settings** → **Branches**
2. 点击你的分支 → **Configure**
3. 在 **Build** 选项卡中：
   - **Build script**: 选择 "Use a build script"
   - **Script content**:
     ```bash
     cd esp-ble-ota
     pod install
     xcodebuild \
       -workspace esp-ble-ota.xcworkspace \
       -scheme esp-ble-ota \
       -configuration Debug \
       -sdk iphoneos \
       -archivePath $APPCENTER_OUTPUT_DIRECTORY/esp-ble-ota.xcarchive \
       CODE_SIGNING_IDENTITY="Apple Development" \
       PROVISIONING_PROFILE_SPECIFIER="" \
       | xcpretty
       
     # 导出IPA
     xcodebuild \
       -exportArchive \
       -archivePath $APPCENTER_OUTPUT_DIRECTORY/esp-ble-ota.xcarchive \
       -exportPath $APPCENTER_OUTPUT_DIRECTORY/build \
       -exportOptionsPlist ExportOptions.plist \
       -allowProvisioningUpdates
     ```

4. 在 **Sign Build** 选项卡中：
   - **Signature Distribution**: 选择 "Manual signing"
   - 上传你的 `.p12` 证书和 `.mobileprovision` 描述文件
   - 输入证书密码

💡 **提示**: 这些证书文件只需要上传一次，以后所有构建都会自动使用！

---

## ▶️ 触发第一次编译

### 方式A: 自动触发（推荐）
```bash
# 只要推送代码到main分支，就会自动编译！
git add .
git commit -m "Trigger automatic build"
git push origin main
```

### 方式B: 手动触发
```
App Center Dashboard → 
选择应用 → 
Build标签 → 
点击 "Build new version" → 
选择分支 → 
点击 "Build now"
```

---

## 📥 下载编译好的IPA

编译成功后（约10-15分钟）：

### 方法1: 直接下载（最简单）
```
App Center → 
选择应用 → 
Build → 
点击最新的successful build → 
右侧 "Download build" 按钮
```
📎 直接下载 `.ipa` 文件！

### 方法2: 通过链接分享
每个构建都有唯一的下载链接：
```
https://install.appcenter.ms/orgs/{org-name}/apps/{app-name}/distribution_groups/{group}/install_link
```
可以发送给任何人安装测试！

### 方法3: 安装到iPhone（无需Mac）

#### 方案1: 使用TestFlight（官方推荐）
- App Center可以直接集成TestFlight
- 设置方法: Distribute → TestFlight → Connect

#### 方案2: 使用企业签名分发（蒲公英/fir.im）
1. 下载IPA后上传到 https://www.pgyer.com/
2. 他们会用企业证书重新签名
3. 生成二维码/链接，扫码即可安装
4. **无需Apple Developer账号！**

#### 方案3: 使用AltStore（免费）
- Windows/Mac都支持
- 有效期7天
- 教程: https://altstore.io/

---

## 🔔 自动通知设置

编译完成后自动通知你：

### Email通知
```
Settings → Notifications → 
Email: ✅ 勾选 "Build completed successfully"
```

### Slack/Teams集成
```
Settings → Integrations → 
Slack/Microsoft Teams → 
Connect workspace → 
选择频道接收通知
```

### Webhook通知
```
Settings → Webhooks → 
New Webhook → 
URL: https://your-server.com/webhook → 
Events: ✅ Build completed
```

---

## 💰 免费额度说明

| 功能 | 免费额度 | 你的使用量 |
|------|---------|-----------|
| **编译时长** | **无限** ✅ | 每次约15分钟 |
| **构建次数** | **无限** ✅ | 无限制 |
| **存储空间** | 2GB | IPA约20MB |
| **团队成员** | 5人 | 够用 |
| **保留历史** | 最近30个构建 | 够用 |

**结论: 个人开发者完全免费，不需要付费！**

---

## 🔄 高级自动化场景

### 场景1: 每天定时编译Nightly版本
```
Build → Settings → Schedule builds → 
Enable scheduled builds → 
Time: 02:00 AM (UTC+8) → 
Frequency: Daily → 
Save
```
每天凌晨自动编译最新代码！

### 场景2: PR自动编译测试
```
Settings → Build → 
Pull Request builds: ✅ Enable → 
Save
```
每次提交PR自动编译验证！

### 场景3: 多环境同时编译
创建多个分支:
- `main` → Production版本
- `develop` → 开发版
- `feature/test` → 测试版

每个分支独立编译，互不影响！

---

## ❓ 常见问题

### Q1: 编译失败 "No signing certificate"
**解决**: 
- 确保已上传有效的.p12证书
- 或使用App Center的自动签名功能（需要先在Apple Developer后台创建证书）

### Q2: "pod install失败"
**解决**: 
- 检查网络连接
- 或在Build script中添加镜像源:
  ```bash
  pod repo update
  pod install --repo-update
  ```

### Q3: 如何更新证书？
```
Build → Settings → Branches → 
编辑分支 → Sign Build选项卡 → 
重新上传新的.p12和.mobileprovision文件
```

### Q4: 编译太慢怎么办？
- 首次编译较慢（~20分钟），后续有缓存会快很多（~10分钟）
- 可以开启增量编译减少时间

### Q5: 不想用Apple Developer账号？
**方案**: 
1. 使用App Center编译出未签名的IPA
2. 上传到蒲公英 (pgyer.com) 或 fir.im
3. 使用他们的**企业证书免费签名**
4. 扫码直接安装到iPhone
5. **完全免费，无需$99/年！**

---

## 📊 与其他方案对比

| 特性 | App Center | GitHub Actions | 蒲公英 | Codemagic |
|------|-----------|----------------|--------|-----------|
| **免费额度** | ✅ **无限** | 2000分钟/月 | 有限免费 | 500分钟/月 |
| **配置难度** | ⭐⭐ 简单 | ⭐⭐⭐ 中等 | ⭐ 最简 | ⭐⭐ 简单 |
| **自动签名** | ✅ 支持 | 需手动配置 | ✅ 企业签名 | ✅ 支持 |
| **分发安装** | ✅ 内置 | 需自行处理 | ✅ 二维码 | 需自行处理 |
| **通知集成** | ✅ 丰富 | 基础 | ✅ 支持 | ✅ 支持 |
| **UI界面** | ✅ 友好 | 命令行 | ✅ 中文 | ✅ 友好 |

**结论: App Center是个人开发者的最佳选择！**

---

## ✅ 配置检查清单

- [ ] 注册App Center账号
- [ ] 创建iOS应用
- [ ] 连接GitHub仓库
- [ ] 配置Build script（或上传签名文件）
- [ ] 触发第一次编译
- [ ] 下载并测试IPA
- [ ] 配置通知（可选）
- [ ] 设置自动化规则（可选）

**预计总时间**: 5-10分钟（首次）  
**后续操作**: 只需 `git push`，全自动完成！

---

## 🆘 需要帮助？

- **文档**: https://docs.microsoft.com/appcenter/build/ios/
- **社区论坛**: https://github.com/microsoft/appcenter/issues
- **状态页面**: https://status.appcenter.ms/

---

## 🎯 下一步建议

1. **立即开始**: 按照"快速开始"3步骤操作
2. **首次编译**: 预计10-15分钟后获得第一个IPA
3. **测试安装**: 使用AltStore或蒲公英安装到iPhone
4. **享受自动化**: 以后每次push代码就自动编译！

**祝你使用愉快！** 🚀