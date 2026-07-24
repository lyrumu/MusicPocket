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

## 仓库结构

```
Music_Pocket/               ← Git 根目录
├── .gitignore              # 忽略 namida/
├── AGENTS.md
├── DONE.md                 # 每完成一个小功能后更新
├── music_pocket/           ← Flutter 项目（所有命令在此目录下执行）
│   ├── pubspec.yaml
│   ├── lib/
│   ├── test/
│   └── ...
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

| 目录                                                        | 状态                                            |
| ----------------------------------------------------------- | ----------------------------------------------- |
| `music_pocket/lib/providers/`                               | **空** — 所有状态管理从这里开始                 |
| `music_pocket/lib/data/daos/`                               | **空** — 需要为每张 Drift 表写 DAO              |
| `music_pocket/lib/data/repositories/`                       | **空** — 需要写 Repository                      |
| `music_pocket/lib/core/constants/`、`utils/`、`extensions/` | **空**                                          |
| `music_pocket/lib/screens/{playlist,settings}/`             | **空**                                          |
| `music_pocket/*.freezed.dart`、`*.g.dart`、`*.drift.dart`   | **仓库里不存在** — 需要运行 `build_runner` 生成 |

## 命令（都必须在 `music_pocket/` 目录下执行）

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
- **生成文件未提交到仓库** — 修改了 `@freezed` 模型、`@riverpod` provider 或 Drift 表定义后，必须运行 `build_runner`。
- **Windows 优先** — 确保所有改动在 Windows/IOS/macOS 上能编译运行。Android/Web 是次要的。
- **`pubspec.yaml` 设置了 `generate: true`**（Flutter 资源代码生成已开启）。
- 所有音频文件保留在本地，**不要上传到任何地方**。
- `.gitignore` 分两层：根目录忽略 `namida/`，`music_pocket/.gitignore` 处理 Flutter 标准忽略规则。

## 规则

1. **使用 namida 前先问我** — 不能盲目复制代码 我只需要namida的部分功能 同时将添加我认为额外需要的功能。
2. **一次只做一个小功能** — 完成后更新 `DONE.md`。
3. **持续更新本文件** — 发现新的注意事项就加进来。
4. **有不明确的需求必须先问我** - 禁止胡乱猜测
