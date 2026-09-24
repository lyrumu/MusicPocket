<p align="center">
  <img src="assets/readme-cover-rounded.svg" alt="Music Pocket：本地音乐资料库、播放界面与音频导入的品牌概念图" width="100%">
</p>

# Music Pocket

把自己的音乐，放进口袋。

Music Pocket 是一款本地优先的跨平台音乐播放器。导入音频后，即可在设备上整理资料库、创建歌单并离线播放。音乐文件不会上传；应用不依赖服务端，也不提供在线串流。

> 项目仍在开发中，预编译安装包尚未公开发布。

## 功能

- 导入音频文件或扫描文件夹，支持 MP3、FLAC、WAV、OGG、M4A、AAC、WMA 和 Opus
- 查看和编辑歌曲信息、专辑封面，按歌曲、艺术家和歌单浏览资料库
- 搜索本地音乐，管理播放队列，选择顺序、单曲循环或随机播放
- 后台播放与系统媒体控制
- 按文件内容识别重复导入，查看存储占用并清理未引用的应用托管文件
- 适配手机与桌面布局，支持深色和浅色主题

导入的音频会复制到应用管理目录，原始文件保留在原位置。删除歌曲时，应用只处理自己管理的副本和不再使用的封面。

## 平台状态

| 平台 | 当前验证情况 |
| --- | --- |
| iOS | iOS 15+；已在 iPhone 真机运行，访客需按教程自行部署 |
| macOS | macOS 12+；已完成 Release 通用架构构建，未使用 Developer ID 签名或公证，其他 Mac 尚未验证 |
| Android | Release 签名配置已准备；缺少本机 SDK、私有密钥和设备验证，尚无 APK |
| Windows | 工程及打包步骤已准备；Release 构建和 Windows 设备验证尚未完成 |

## 从源码运行

需要 Flutter 3.44+。在项目根目录执行：

```bash
flutter pub get
flutter devices
flutter run -d <device-id>
```

iOS 暂不提供安装包；Mac 用户可参考[自行部署到 iPhone 的教程](https://lyrumu.top/notes/flutter%E9%A1%B9%E7%9B%AE%E9%83%A8%E7%BD%B2%E8%87%B3ios/)，在 Xcode 中为本项目配置自己的开发签名。其他平台的运行情况请以上表为准。

## 本地打包

以下步骤供本地手动构建；构建产物上传 GitHub Releases 前，仍需在对应设备上验证安装、导入和播放。

### macOS ZIP

应用最低要求 macOS 12；已在 macOS 26.6.2、Flutter 3.44.8 与 Xcode 27 上构建包含 Intel 和 Apple 芯片架构的 Release 应用。本机 Flutter SDK 中的 `font-subset` 工具被系统拦截，故构建时关闭图标字体裁剪；这不会移除应用功能。

```bash
# 获取项目依赖
flutter pub get
# 构建 macOS Release，避开本机被拦截的图标字体裁剪工具
flutter build macos --release --no-tree-shake-icons
# 创建本地打包目录
mkdir -p build/releases
# 保留应用包结构及资源元数据并生成 ZIP
ditto -c -k --sequesterRsrc --keepParent 'build/macos/Build/Products/Release/Music Pocket.app' build/releases/MusicPocket-macos-universal.zip
```

目前没有 Apple Developer Program 的 Developer ID 证书，因此该 ZIP 只有构建时的临时签名，未经过 Developer ID 签名或公证。从 GitHub 下载后，macOS 可能阻止首次打开；确认来源后可按 [Apple 官方步骤](https://support.apple.com/zh-cn/102445)在“系统设置 → 隐私与安全性”中选择“仍要打开”。不要关闭整个系统的安全检查。

### Android APK

先在本机安装 Android SDK 和 JDK，用 `flutter doctor -v` 检查。首次发布前，用 `keytool` 在仓库外创建并备份自己的签名密钥；密钥及密码丢失后，后续 APK 将无法以原签名覆盖安装。将下面的路径改为你自己选定的私有位置，执行时按提示设置密码：

```bash
# 在仓库外创建长期保管的 Android 签名密钥
keytool -genkeypair -v -keystore /absolute/private/path/music-pocket-release.jks -storetype PKCS12 -keyalg RSA -keysize 2048 -validity 10000 -alias music-pocket
```

在本机创建 `android/key.properties`（已被 `android/.gitignore` 忽略），填入实际密码和密钥绝对路径：

```properties
storePassword=你的密钥库密码
keyPassword=你的密钥密码
keyAlias=music-pocket
storeFile=/absolute/private/path/music-pocket-release.jks
```

Windows 上填写 `storeFile` 时，路径中的反斜杠需写成双反斜杠。不要提交 `key.properties`、密钥或密码。缺少这些配置时，Android Release 构建会明确失败；Debug 构建不需要发布密钥。

```bash
# 获取项目依赖
flutter pub get
# 构建已签名的 APK
flutter build apk --release

# 查看已连接的 Android 设备
flutter devices
# 将 APK 安装到已连接设备
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

APK 位于 `build/app/outputs/flutter-apk/app-release.apk`。后续发布保持同一密钥，并在 `pubspec.yaml` 中递增 `version` 的 `+` 后构建号。更多细节见 [Flutter Android 发布文档](https://docs.flutter.dev/deployment/android)。

### Windows x64 压缩包

在 Windows 上安装 Flutter 与 Visual Studio 的“使用 C++ 的桌面开发”工作负载，确认 `flutter doctor -v` 后，在项目根目录用 PowerShell 执行：

```powershell
# 获取项目依赖
flutter pub get
# 构建 Windows x64 Release
flutter build windows --release

# 将整个 Release 目录的内容打成 ZIP，保留 DLL 和 data 目录
Compress-Archive -Path .\build\windows\x64\runner\Release\* -DestinationPath .\build\MusicPocket-windows-x64.zip -Force
```

解压后运行 `music_pocket.exe`；请在 Windows 实机核对导入、播放与资料库。目标电脑还需要 Microsoft Visual C++ 运行库，见 [Flutter Windows 分发说明](https://docs.flutter.dev/platform-integration/windows/building)。当前没有 Windows 代码签名证书，下载后的程序可能触发 [SmartScreen 提示](https://learn.microsoft.com/en-us/windows/apps/package-and-deploy/smartscreen-reputation)。

## 发布前

先在对应设备验证每个产物，再通过 [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository) 创建预发布版本并上传已验证的 APK、macOS ZIP 和 Windows ZIP；iOS 只提供上面的自行部署教程。`build/` 已被 Git 忽略，提交源码不会自动附带安装包。未完成验证的平台不要标记为可直接使用。

## 技术栈

Flutter / Dart · Riverpod · Drift / SQLite · just_audio / audio_service · audio_metadata_reader

运行 `flutter analyze` 和 `flutter test` 可检查代码；开发记录见 [DONE.md](DONE.md)。
