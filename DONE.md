# 完成清单
置顶信息：
1.构建命令提示：cd music_pocket && flutter run -d macos

## ✅ 第 1 步：编译基础设施
- 补 `pubspec.yaml` 依赖：`freezed_annotation`、`json_annotation`、`freezed`、`json_serializable`、`audio_metadata_reader`（替换 `on_audio_query`）
- 下载 Inter 字体（Regular/Medium/SemiBold/Bold）到 `assets/fonts/`
- 跑 `flutter pub run build_runner build` 生成全部 freezed/json/riverpod/drift/dao 代码
- 重写 `widget_test.dart` 为 `MusicPocketApp` smoke test
- 重写 `metadata_service.dart` 为 `audio_metadata_reader`（纯 Dart，跨平台支持 MP3/MP4/FLAC/OGG/Opus/WAV/AIFC/APE）

## ✅ 第 2 步：数据层
- `lib/data/daos/track_dao.dart`：`@DriftAccessor(tables: [Tracks])`，手写扩展查询（watchAll/watchById/watchByFolder/search/getById/getByFilePath/getAllFilePaths/insert/update/delete/toggleFavorite/markPlayed/setCoverPath/setUserEdited）
- `lib/data/repositories/track_repository.dart`：导入业务逻辑（复制音频到 `<docs>/audio/`，提取封面 → `<docs>/covers/`，入库 + dedupe by filePath），自定义封面保存，编辑元数据（标记 isUserEdited=true），切换收藏，删除
- `Tracks` 表加 `isUserEdited` 列；schemaVersion 2 + `onUpgrade` migration

## ✅ 第 3 步：Providers
- `lib/providers/database_provider.dart`：`appDatabaseProvider`、`metadataServiceProvider`、`trackRepositoryProvider`
- `lib/providers/track_provider.dart`：`tracksProvider`（StreamProvider）、`searchTracksProvider`、`currentTrackProvider`、`playModeProvider`
- 重构 `AudioPlayerService`：queue 改为 `List<Track>`、暴露 `currentTrack`、`currentTrackStream`、`playModeStream`

## ✅ 第 4 步：MetadataService 跨平台
- 已在第 1 步完成。`MetadataService.extractMetadata()` 返回 `TrackMetadata` 含字段 + `coverBytes`（Uint8List）+ `coverMimeType`

## ✅ 第 5 步：实现真实导入
- `lib/screens/import/import_screen.dart` 重写：使用 `trackRepositoryProvider.importPath()`，显示进度条（n/total、当前文件名）、成功/跳过/失败计数 snackbar
- 文件选择器（`FilePicker.platform.pickFiles`）和文件夹扫描（`Directory.list`）均连到同一 `_addPaths`

## ✅ 第 6 步：接通 UI
- `TrackListTile` 改为接受 `Track` 参数 + 显示封面（`CoverImage`）
- `lib/screens/library/library_screen.dart`：歌曲 Tab 接 `tracksProvider`，点击 → `AudioPlayerService.playTracks(...)`；专辑/艺术家/文件夹 Tab 显示统计占位
- `lib/widgets/player/mini_player.dart` → `ConsumerWidget`，接 `currentTrackProvider`，真实封面/标题/艺术家
- `lib/screens/player/player_screen.dart` → `ConsumerWidget`，接 `currentTrackProvider` + 滑块绑定 `positionStream`/`duration` streams + 收藏/播放模式
- `app.dart` 初始化 DB provider，并订阅 `currentTrackStream` → 自动 `markPlayed`
- `lib/widgets/common/cover_placeholder.dart` 通用封面组件（File → 占位渐变兜底）
- `lib/core/extensions/track_extensions.dart` 提供 `displayTitle/Artist/Album/durationFormatted`

## ✅ 第 7 步：用户自定义覆盖
- 新表列 `isUserEdited: boolean default false`
- `lib/widgets/library/track_edit_sheet.dart`：长按歌曲 → 底部弹出编辑面板（标题/艺术家/专辑/流派/年份 + 自定义封面/删除自定义封面 + 删除歌曲）
- `Repository.editTrackMetadata` 写入时合并 `isUserEdited=true`
- `Repository.setCustomCover` 写入时合并 `isUserEdited=true`
- `Repository.importPath` 已对同一 filePath 跳过不入库 → 用户编辑不会被后续导入覆盖

## ✅ 第 8 步：验证
- `flutter analyze`: **No issues found**
- `flutter test`: **All tests passed!** (1/1)
- `flutter build windows --debug`: ⚠️ 需要先在系统设置启用 Developer Mode（symlink 支持）

## ✅ 第 9 步：锁屏/后台接通
- `lib/services/audio_handler.dart`：`MusicPocketAudioHandler extends BaseAudioHandler with SeekHandler`，桥接系统通知/锁屏按钮到 `AudioPlayerService`
- `AudioPlayerService.attachHandler`：订阅 just_audio `playerStateStream` → 同步 `playbackState`；订阅 `currentTrackStream` → 推 `MediaItem`（标题/艺术家/封面Uri/时长）；处理歌曲自然结束 → 自动下一首（单曲循环下回放）
- `lib/main.dart`：`AudioService.init(...)` 初始化 + 挂载到 `AudioPlayerService.instance`
- `ios/Runner/Info.plist`：加 `UIBackgroundModes = audio`，iOS 后台播放不停

## ✅ 第 10 步：Windows 音频后端
- pubspec 加 `just_audio_media_kit: ^2.0.0` + `media_kit_libs_windows_audio: ^1.0.9`
- 不改业务代码，依赖加载后 just_audio 在 Windows 自动注册 media_kit 实现

## ✅ 第 11 步：UI 重构（用户 3 项需求）
- 新建 `lib/providers/theme_provider.dart`：`isDarkThemeProvider = StateProvider<bool>`，默认深色
- `app.dart`：去掉 `onToggleTheme` 回调链，改为读 `isDarkThemeProvider` 驱动 `themeMode`
- `home_screen.dart`：加全局顶栏，左侧 `MusicPocket` 品牌（Inter w700 + letter-spacing -0.5 + accent 色），右侧主题切换按钮（带 `AnimatedSwitcher` 图标动画），任何底部 Tab 都显示
- `library_screen.dart`：去掉「资料库」标题行；Tab 从 4 个（歌曲/专辑/艺术家/文件夹）改为 3 个（歌曲/艺术家/歌单）；「+」导入按钮并到 TabBar 行尾；新增「歌单」placeholder
- 设置页只剩「关于」入口（主题切换移到全局）

## ✅ 第 12 步：Windows 音频后端注册
- `main.dart`：`JustAudioMediaKit.ensureInitialized()` 必须在创建 `AudioPlayer()` 之前调用，否则 just_audio 退回 mobile method channel → `MissingPluginException` + 无声
- pubspec 加 `just_audio_media_kit: ^2.1.0`（仅 `_audioService` 一个直接依赖，去掉 `media_kit`）

## ✅ 第 13 步：Mini Player 体验三项修复
- 进度条可拖动：`LinearProgressIndicator` → `Slider`（trackHeight 2 + 小拇指），边拖边预览 `playModeProvider`，松手才 `seek`，避免抖动
- 顺序播放"隔一首"修复：完成事件 guard 改为只在 `processingState` 离开 `completed` 时重置（之前在 `seek(Duration.zero)` 后立刻 false 会让重复 `completed` 再触发一次 `playNext`）
- 播放模式按钮直接挂在 MiniPlayer 控制栏左侧（循环/单曲循环/随机），无需展开全屏播放器即可切换

## ✅ 第 14 步：修复 macOS 导入无响应
- 根因：macOS App Sandbox 未声明文件访问权限，`file_picker` 被静默阻止，点击「选择文件/选择文件夹」无反应
- `macos/Runner/DebugProfile.entitlements` 与 `macos/Runner/Release.entitlements` 增加 `com.apple.security.files.user-selected.read-write`
- `lib/screens/import/import_screen.dart`：`_pickFiles`/`_pickFolder` 添加 try-catch，选择失败时通过 SnackBar 提示用户

## ✅ 第 15 步：PlayerScreen 垂直溢出修复
- 根因：`PlayerScreen` body 的 `SafeArea → Column` 固定子项总高约 660px，超出 macOS 默认窗口 600px。两个 `Spacer` 在负剩余空间下无法压缩，`RenderFlex OVERFLOWING`
- 修复：`Column` 外套 `LayoutBuilder → SingleChildScrollView → ConstrainedBox(minHeight) → IntrinsicHeight`
- 内容 ≤ 视口时：`ConstrainedBox` 拉到满高，`IntrinsicHeight` 给 `Spacer` 有界高度，封面居中留白不变
- 内容 > 视口时：超出的内容可滚动
- 规避了 `SingleChildScrollView(Column(Spacer))` 的 `unbounded height` 坑

## ✅ 第 16 步：歌曲列表自定义信息入口
- 需求：导入歌曲时自动保留音频自带封面/作者/专辑等默认信息，同时允许用户在歌曲列表中自定义这些信息
- 实现：
  - `lib/widgets/library/track_list_tile.dart`：新增 `onEdit` 回调；在 trailing 区域（时长左侧）显示「编辑」图标按钮
  - `lib/screens/library/library_screen.dart`：为每个 `TrackListTile` 传入 `onEdit`，点击后弹出 `TrackEditSheet`
- 自定义编辑面板（`TrackEditSheet`）支持：标题、艺术家、专辑、流派、年份、自定义封面/移除封面、删除歌曲；保存后自动标记 `isUserEdited=true`
- 导入逻辑（`TrackRepository.importPath`）按 `filePath` 去重，已编辑的歌曲不会被后续重复导入覆盖

## ✅ 第 17 步：修复 Mini Player 进度条 + App 内置音量控制
- 修复 `mini_player.dart` 进度条：duration 未加载时若 positionStream 残留旧位置，会被 clamp 到终点；现在 `duration <= 0` 或 `position > duration` 时一律回到起点
- 内置音量控制：`AudioPlayerService` 加 `setVolume` / `volume` / `volumeStream`（just_audio 应用级音量，不影响系统音量）
- `lib/widgets/common/volume_control.dart`：音量图标 + 小 Slider，放在 `home_screen.dart` 顶栏主题切换按钮旁边
- 验证：`build_runner` / `flutter analyze` / `flutter test` 均通过

## ✅ 第 18 步：艺术家页面
- `lib/providers/artist_provider.dart`：从全部曲目按 `artist` 分组，生成 `Artist` 列表（含封面、曲目数）
- `lib/screens/library/library_screen.dart`：艺术家 Tab 改为真实列表，点击后进入 `ArtistDetailScreen`
- `lib/screens/library/artist_detail_screen.dart`：AppBar 封面 + 播放全部按钮 + 曲目列表，点击歌曲直接播放该艺术家全部曲目
- 验证：`build_runner` / `flutter analyze` / `flutter test` 均通过

## ✅ 第 19 步：歌单管理
- 数据层：
  - `lib/data/daos/playlist_dao.dart`：新增 `@DriftAccessor(tables: [Playlists, PlaylistTracks, Tracks])`，支持创建/重命名/删除歌单、加入/移除歌曲、查询歌单曲目、统计歌单内歌曲数
  - `lib/data/repositories/playlist_repository.dart`：业务封装
  - `lib/data/database/app_database.dart`：加 `playlistDao` 字段
- 状态层：
  - `lib/providers/database_provider.dart`：新增 `playlistRepositoryProvider`
  - `lib/providers/playlist_provider.dart`：`playlistsProvider`、`playlistTracksProvider`
- UI：
  - `lib/screens/library/playlist_tab.dart`：歌单列表 + 新建/重命名/删除
  - `lib/screens/library/playlist_detail_screen.dart`：歌单曲目列表 + 播放全部 + 左滑移除歌曲
  - `lib/widgets/library/add_to_playlist_sheet.dart`：从歌曲库/艺术家页把歌曲加入已有歌单（或新建歌单）
  - `lib/widgets/library/track_list_tile.dart`：加 `onAddToPlaylist` 回调，显示「加入歌单」图标
  - `lib/widgets/common/text_input_dialog.dart`：复用的新建/重命名对话框
- 验证：`build_runner` / `flutter analyze` / `flutter test` 均通过

## ✅ 第 20 步：MiniPlayer 全局一致性 + 歌单封面 + 导入入口下移
- 艺术家/歌单详情页底部加 `MiniPlayer`，点击歌曲后 mini player 立刻弹出，与首页一致
  - `lib/screens/library/artist_detail_screen.dart`：body 改为 `Column[Expanded(CustomScrollView), MiniPlayer?]`，mini player 点击可进全屏播放器
  - `lib/screens/library/playlist_detail_screen.dart`：同上
- 歌单封面默认取第一首添加歌曲的封面
  - `lib/data/daos/playlist_dao.dart`：`watchAllWithTrackCount()` 增加 `first_cover_path` 子查询；`PlaylistWithTrackCount` 加 `coverPath`
  - `lib/screens/library/playlist_tab.dart`：列表项 leading 显示封面或默认图标
  - `lib/screens/library/playlist_detail_screen.dart`：详情页 AppBar 背景也显示封面
- 导入入口从「资料库」右上角移到底部导航栏「播放列表」与「搜索」之间
  - `lib/screens/home/home_screen.dart`：底部导航 5 项（资料库/播放列表/导入/搜索/设置），点「导入」直接 push `ImportScreen`
  - `lib/screens/library/library_screen.dart`：移除右上角 `+` 导入按钮和对应方法，空状态提示改为「点击底部导入按钮添加音频」
- 验证：`build_runner` / `flutter analyze` / `flutter test` 均通过

## ✅ 第 21 步：修复 mini 播放器进度 + 清理调试产物
- 修复 `main.dart`：`JustAudioMediaKit.ensureInitialized()` 改为仅在 Windows/Linux 调用，避免破坏 macOS/iOS 原生音频后端
- 增强 `AudioPlayerService`：新增 `_duration` 字段并订阅 `durationStream`，`duration` getter 返回最新已知值，不再在 duration 加载前返回 0
- 重构 `MiniPlayer` 进度条：外层监听 `durationStream`、内层监听 `positionStream`，duration 加载后 slider 立即重建
- 清理所有 `TRAE-debugger` 调试插桩代码（`_debugLog`、`.dbg/` 引用、临时测试数据）
- 移除 `app.dart` 中自动导入测试音频/创建调试歌单/自动播放的种子逻辑
- 删除 `.dbg/` 目录及 `debug-mini-progress-playlist-cover.md` 调试记录文件
- 验证：`flutter analyze` 通过（仅剩 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（1/1）

## ✅ 第 22 步：歌单封面取第一首有封面歌曲 + 持久化测试
- 歌单封面逻辑已在第 20 步实现，现补全边界情况并加测试
  - `lib/data/daos/playlist_dao.dart`：`watchAllWithTrackCount()` 子查询改为 `ORDER BY position` 并跳过 `cover_path IS NULL/''`，取歌单内第一首有封面歌曲
  - `lib/screens/library/playlist_detail_screen.dart`：AppBar 背景与列表侧栏采用同样的回退逻辑（第一首有封面歌曲）
- 为可测试性给 `AppDatabase` 加 `@visibleForTesting` 内存构造器
- 新增 `test/playlist_cover_test.dart`：覆盖「第一首有封面」「空歌单」「先加入无封面歌曲时回退到下一首」三种场景
- 验证：`flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ⚠️ 环境注意事项（更新到 AGENTS.md）
- 系统没有 Rust 工具链 → 不能用 `metadata_god`，已切到 `audio_metadata_reader`（纯 Dart）
- Windows 完整构建需开启系统 Developer Mode（用于 plugin symlinks）。`flutter test`/`flutter analyze` 不受影响
- 数据库文件位置：`getApplicationDocumentsDirectory()/music_pocket/music_pocket.db`
- 导入的音频副本：`<docs>/music_pocket/audio/<microsec>.<ext>`
- 提取的封面：`<docs>/music_pocket/covers/<microsec>.<ext>`

## 文件清单
```
music_pocket/lib/
├── main.dart                                  # 入口（已 OK）
├── app.dart                                   # ProviderScope + DB 初始化 + markPlayed 监听
├── core/
│   ├── theme/app_theme.dart, app_colors.dart  # Material 3 主题
│   └── extensions/track_extensions.dart       # display* / durationFormatted
├── data/
│   ├── database/app_database.dart, .g.dart   # Drift schema v2
│   ├── daos/track_dao.dart, .g.dart           # @DriftAccessor
│   ├── daos/playlist_dao.dart, .g.dart        # 歌单相关 Drift 查询
│   ├── repositories/track_repository.dart     # 曲目业务封装
│   ├── repositories/playlist_repository.dart  # 歌单业务封装
│   └── models/{track,playlist,category}.dart   # Freezed Model（名称用 Model 后缀避免与 Drift 行类冲突）
├── providers/
│   ├── database_provider.dart                 # db/repo/metadata
│   ├── track_provider.dart                    # tracks/currentTrack/playMode
│   ├── artist_provider.dart                 # 艺术家分组
│   └── playlist_provider.dart               # 歌单/歌单曲目
├── services/
│   ├── audio_player_service.dart              # Track-based queue + 流式状态 + 应用音量
│   └── metadata_service.dart                  # audio_metadata_reader
├── screens/
│   ├── home/home_screen.dart                  # 4-Tab 导航 + 音量/主题顶栏
│   ├── library/library_screen.dart            # 歌曲/艺术家/歌单 Tab
│   ├── library/artist_detail_screen.dart      # 艺术家详情/曲目
│   ├── library/playlist_tab.dart              # 歌单列表
│   ├── library/playlist_detail_screen.dart    # 歌单曲目
│   ├── import/import_screen.dart              # 真实导入 + 进度
│   └── player/player_screen.dart              # 完整播放器
└── widgets/
    ├── common/cover_placeholder.dart          # 封面组件
    ├── common/volume_control.dart             # 顶栏音量控制
    ├── common/text_input_dialog.dart          # 新建/重命名输入框
    ├── library/track_list_tile.dart           # Track 行（加入歌单/编辑）
    ├── library/track_edit_sheet.dart          # 编辑面板（自定义覆盖）
    ├── library/add_to_playlist_sheet.dart     # 加入歌单
    └── player/mini_player.dart                # MiniPlayer（实时跟当前曲目）

test/
├── widget_test.dart                           # App smoke test
└── playlist_cover_test.dart                   # 歌单封面 DAO 测试
```
