# iOS 云端编译完整指南

## 📋 前置条件

### 1. Apple Developer 账号
- **个人账号** ($99/年): 可用于开发和测试
- **企业账号** ($299/年): 可用于内部分发
- **免费账号**: 仅限真机调试，无法生成IPA

### 2. 必需的Apple资源

#### 🔑 开发证书 (Development Certificate)
1. 登录 [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/add)
2. 选择 **Apple Development** 证书类型
3. 上传CSR文件（证书签名请求）
   - Mac上：钥匙串访问 → 证书助理 → 从证书颁发机构请求证书...
4. 下载并安装 `.cer` 文件
5. 导出为 `.p12` 格式（包含私钥）

#### 📱 描述文件 (Provisioning Profile)
1. 在 Apple Developer Portal 创建 App ID
   - Bundle ID: `com.espressif.esp-ble-ota`
2. 创建描述文件
   - 类型: **iOS App Development**
   - 关联证书和App ID
3. 下载 `.mobileprovision` 文件

#### 👥 团队ID (Team ID)
- 在 [Apple Developer Account](https://developer.apple.com/account/#/membership) 查找

---

## 🔧 GitHub Actions 配置步骤

### 步骤 1: Fork 或上传项目到 GitHub

```bash
# 如果还没有GitHub仓库
cd esp-ble-ota-ios
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/esp-ble-ota-ios.git
git push -u origin main
```

### 步骤 2: 配置 GitHub Secrets

进入你的 GitHub 仓库 → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

需要添加以下 Secrets：

#### ① BUILD_CERTIFICATE_BASE64
```bash
# 将.p12证书转换为Base64（Mac/Linux）
base64 -i YourCertificate.p12 | pbcopy
# Windows:
certutil -encode YourCertificate.p12 cert.txt && type cert.txt
```
将输出粘贴到Secret值中。

#### ② P12_PASSWORD
导出p12文件时设置的密码。

#### ③ KEYCHAIN_PASSWORD
自定义的keychain密码（用于CI环境）。

#### ④ PROVISIONING_PROFILE_BASE64
```bash
# 将.mobileprovision转换为Base64
base64 -i profile.mobileprovision | pbcopy
```

#### ⑤ APPLE_TEAM_ID
你的Apple开发者团队ID（10位字符串）。

### 步骤 3: 触发编译

#### 方式A: 手动触发
1. 进入仓库的 **Actions** 标签页
2. 选择 **iOS Build** 工作流
3. 点击 **Run workflow**
4. 选择分支并点击 **Run workflow**

#### 方式B: 自动触发
推送代码到 `main` 或 `develop` 分支会自动触发编译：
```bash
git push origin main
```

### 步骤 4: 下载 IPA 文件

编译成功后：

1. 进入 **Actions** → 点击对应的workflow run
2. 滚动到底部的 **Artifacts** 区域
3. 下载 `iOS-App-Debug-xxxxx.zip`
4. 解压得到 `.ipa` 文件

---

## 📲 安装IPA到设备

### 方法1: 使用AltStore（推荐，免费）

1. 安装 [AltServer](https://altstore.io/) 到电脑
2. 连接iPhone到电脑
3. 打开AltServer，安装AltStore到iPhone
4. 在iPhone上打开AltStore，导入IPA文件
5. **有效期7天**，需要重新签名

### 方法2: 使用Apple Configurator 2（Mac专属）

1. Mac App Store下载 **Apple Configurator 2**
2. iPhone连接Mac
3. Apple Configurator 2 → **添加** → 选择IPA文件
4. 需要信任开发者证书：设置 → 通用 → VPN与设备管理 → 信任证书

### 方法3: 使用Xcode（Mac专属）

1. Xcode → Window → Devices and Simulators
2. 连接iPhone
3. 拖拽IPA文件到"Installed Apps"区域

### 方法4: 使用第三方工具

- **TrollStore** (需要特定iOS版本)
- **Sideloadly** (Windows/Mac支持)
- **3uTools** (Windows)

---

## 💰 成本分析

### GitHub Actions 费用
| Runner类型 | 免费额度 | 超出费用 |
|------------|---------|---------|
| **macOS-latest** | 2,000分钟/月 | $0.08/分钟 |

**估算**: 
- 每次~15分钟编译时间
- 月均30次编译 = 450分钟
- **免费用户足够使用**
- 企业用户可升级付费计划

---

## 🔄 其他云端编译方案对比

### 方案1: GitHub Actions ⭐⭐⭐⭐⭐
✅ **优点**:
- 完全免费（个人项目）
- 与GitHub深度集成
- 自动化程度高
- 社区生态丰富

❌ **缺点**:
- macOS runner有限制
- 需要手动配置secrets
- 首次配置较复杂

💰 **费用**: 免费（公共仓库）/ 付费（私有仓库需GitHub Pro $4/月）

---

### 方案2: Codemagic ⭐⭐⭐⭐
✅ **优点**:
- 专为移动应用设计
- UI友好，易于配置
- 免费额度500分钟/月
- 支持Helmholtz测试

❌ **缺点**:
- 高级功能收费
- 免费额度较少

💰 **费用**: 
- Free: 500分钟/月
- Pro: $49/月起

🔗 [官网](https://codemagic.io/)

---

### 方案3: Bitrise ⭐⭐⭐⭐
✅ **优点**:
- 移动应用CI/CD专业平台
- 丰富的集成选项
- 免费额度充足

❌ **缺点**:
- 学习曲线较陡
- 高级功能昂贵

💰 **费用**:
- Free: 45分钟/天
- Developer: $39/月（2000分钟/月）

🔗 [官网](https://www.bitrise.io/)

---

### 方案4: App Center (Microsoft) ⭐⭐⭐
✅ **优点**:
- 微软出品，稳定可靠
- 免费无限编译时长
- 内置崩溃分析和分发

❌ **缺点**:
- 配置相对复杂
- macOS构建代理有限制

💰 **费用**: 完全免费

🔗 [官网](https://appcenter.ms/)

---

## 🚀 推荐方案

### 对于你的场景，我推荐：

#### 🥇 **首选: GitHub Actions** （已配置完成）
- ✅ 已创建工作流文件
- ✅ 完全自动化
- ✅ 免费且强大
- ✅ 版本控制集成

#### 🥈 **备选: App Center**
- 如果遇到GitHub Actions限制
- 无限免费编译时长
- 内置测试设备管理

---

## ⚠️ 常见问题解决

### Q1: 编译失败 "No signing certificate found"
**原因**: 证书配置错误或过期
**解决**:
1. 检查Secrets是否正确
2. 确保证书未过期
3. 重新导出p12文件

### Q2: "Provisioning profile not found"
**原因**: 描述文件未正确配置或Bundle ID不匹配
**解决**:
1. 确认PROVISIONING_PROFILE_BASE64正确
2. 检查Bundle ID是否匹配
3. 重新生成描述文件

### Q3: IPA无法安装到设备
**原因**: 签名证书不受信任
**解决**:
1. 设置 → 通用 → VPN与设备管理
2. 找到开发者证书并信任
3. 重启设备

### Q4: 编译超时
**原因**: 项目依赖过多或网络慢
**解决**:
1. 在工作流中增加timeout-minutes
2. 使用缓存加速依赖安装

---

## 📞 技术支持

如果遇到问题：
1. 检查 **Actions** 日志中的详细错误信息
2. 查看 [GitHub Actions文档](https://docs.github.com/en/actions)
3. 参考本项目Issues提交问题

---

## ✅ 快速开始清单

- [ ] 注册Apple Developer账号
- [ ] 创建开发证书 (.p12)
- [ ] 创建描述文件 (.mobileprovision)
- [ ] Fork/上传代码到GitHub
- [ ] 配置5个GitHub Secrets
- [ ] 触发第一次编译
- [ ] 下载并安装IPA

**预计总时间**: 2-3小时（首次配置）  
**后续编译**: 5-10分钟自动完成