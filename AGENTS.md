# Music Pocket — Agent Instructions

## 项目

Flutter 3.44+ / Dart ^3.12。跨平台（iOS/Win/Mac/）。本地优先音乐播放器：用户导入音频文件，应用管理和离线播放。无服务端、无流媒体。

| 层       | 技术                                                      |
| -------- | --------------------------------------------------------- |
| 状态管理 | flutter_riverpod + riverpod_generator（`@riverpod`）      |
| 数据库   | drift + sqlite3_flutter_libs                              |
| 音频播放 | just_audio + audio_service + audio_session                |
| 元数据   | on_audio_query                                            |
| 模型     | freezed + json_serializable                               |
| UI       | Material 3，深色/浅色主题。风格参考 Apple Music / Spotify |

参考项目在 `namida/`（同级目录）— **使用 namida 的任何功能前必须先问我**。

## 规则

1. **出现困难问题可优先参考namida/** — 除非你有更好的颠覆性方案
2. **使用 namida 前先问我** — 不能盲目复制代码 我只需要namida的部分功能 同时将添加我认为额外需要的功能。
3. **一次只做一个小功能** — 完成后更新 `DONE.md`。
4. **持续更新本文件** — 发现新的注意事项就加进来。
5. **有不明确的需求必须先问我** - 禁止胡乱猜测


## 仓库结构

```
MusicPocket/                ← Git 根目录，也是 Flutter 项目根目录
├── pubspec.yaml
├── lib/
├── test/
├── android/
├── ios/
├── macos/
├── windows/
├── linux/
├── web/
├── .gitignore              # Flutter 忽略规则及 namida/
├── AGENTS.md
├── DONE.md                 # 每完成一个小功能后更新
└── namida/                 ← 参考项目（已被 .gitignore 排除）
```

## 架构

```
UI（Widgets/Screens）→ Providers（Riverpod）→ Repositories → 数据库（Drift）/ Services
```

- **Services**：纯 Dart 单例，通过 `static final instance = XxService._();` 访问
- **Providers**：使用 `@riverpod` 注解自动生成
- **Widgets** 不能直接调用数据库或文件 I/O
- **代码里不加注释**，除非绝对必要

## 项目现状（关键上下文）

| 目录                         | 状态                                      |
| ---------------------------- | ----------------------------------------- |
| `lib/providers/`             | 已实现主要 Riverpod 状态管理              |
| `lib/data/daos/`             | 已实现 Track / Playlist DAO               |
| `lib/data/repositories/`     | 已实现 Track / Playlist Repository        |
| `lib/core/`                  | 已包含主题和 Track 扩展                   |
| `lib/screens/`               | 已包含主页、资料库、导入、搜索和播放器界面 |
| `lib/**/*.freezed.dart`、`lib/**/*.g.dart` | 生成文件已存在；源定义变更后需重新生成 |

## 命令（都必须在 Git 根目录 `MusicPocket/` 下执行）

```powershell
# 代码生成（freezed + riverpod + drift）
dart run build_runner build --delete-conflicting-outputs

# 静态分析
flutter analyze

# 运行测试
flutter test

# Windows 桌面端运行
flutter run -d windows
```

## 注意事项

- **现有的测试 `test/widget_test.dart` 已过期** — 引用了不存在的 `MyApp`，会运行失败。需要修复后才能信任测试结果。
- **Git 根目录就是 Flutter 项目根目录**；不要再嵌套 `YourPocket/` 或 `music_pocket/`。`pubspec.yaml` 中的内部 Dart 包名仍为 `music_pocket`。
- **用户可见应用名统一为 `Music Pocket`**；Dart 包名、Bundle ID、Android applicationId 和本地数据目录属于内部标识，不要为了修改显示名而改动。
- **生成文件未提交到仓库** — 修改了 `@freezed` 模型、`@riverpod` provider 或 Drift 表定义后，必须运行 `build_runner`。
- **苹果生态优先** — 确保所有改动在 iOS/macOS 上能编译运行。Android/Windows是次要的。
- **`pubspec.yaml` 设置了 `generate: true`**（Flutter 资源代码生成已开启）。
- 所有音频文件保留在本地，**不要上传到任何地方**。
- 根目录 `.gitignore` 同时处理 Flutter 标准忽略规则和 `namida/`。
- **播放器进度条待后续优化**：静默播放时进度与音频一致，但主动拖动/跳跃后在部分歌曲上仍可能发生进度与实际播放不一致；后续需针对 iOS/macOS 的原生 seek 与位置回传做专项验证和修复。
- **封面字段语义**：`coverPath` 是当前展示封面，`originalCoverPath` 是音频内嵌原始封面，`customCoverPath` 是用户自定义封面；清除自定义封面必须恢复 `originalCoverPath`。
- **媒体文件删除边界**：只允许删除应用 `audio/`、`covers/` 目录内的托管文件，绝不能删除用户最初导入位置的原文件；歌曲删除失败时保留数据库记录。

## iOS / macOS 部署备忘

### 上架前需完成的硬性条件
1. **Apple Developer Program**（¥99/年）— 没有它无法签名和分发。
2. **Xcode 首次配置**（mac 本地开发需要）：
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```
3. **Bundle ID 当前值**：`com.lyrumu.musicPocket`（`ios/Runner.xcodeproj` 中设定），上架前需确认是否需要修改。

### iOS 隐私权限
- `ios/Runner/Info.plist` 已预留 `NSAppleMusicUsageDescription`（`on_audio_query` 需要，用于扫描本地音频文件）。
- 如果后续添加涉及麦克风、照片等新功能，需追加对应权限描述。

### macOS 注意
- `macos/Runner/Info.plist` 暂无额外权限需求。
- macOS 桌面端运行：`flutter run -d macos`。

### Podfile
- `ios/Podfile` 和 `macos/Podfile` 由 Flutter 在首次 `flutter build ios` / `flutter run -d macos` 时自动生成，不需要预先创建。
- SwiftPM 依赖获取受网络影响时，可在交互式 zsh 的同一会话中先执行用户自设函数 `proxyon` 再构建；非交互 shell 不会加载该函数。
