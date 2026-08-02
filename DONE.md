# 完成清单
置顶信息：
1.构建命令提示：cd music_pocket && flutter run -d macos
2.每次更新项目后 在此记录的内容应尽量精简 根据实际更新代码量调整

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
│   ├── audio_player_service.dart              # 动态待播队列 + 上下文自动补齐 + 持久化/恢复 + 流式状态
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
    ├── library/track_quick_actions.dart       # 长按曲目菜单（下一首/加入播放列表/加入歌单/编辑/删除）
    ├── player/mini_player.dart                # MiniPlayer（实时跟当前曲目 + 队列按钮）
    └── player/play_queue_sheet.dart           # 播放列表底部抽屉（拖拽排序/删除/点按播放）

test/
├── widget_test.dart                           # App smoke test
└── playlist_cover_test.dart                   # 歌单封面 DAO 测试
```



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

## ✅ 第 23 步：歌单/艺术家歌曲数实时匹配资料库
- 需求：资料库中的歌曲被删除后，歌单与艺术家显示的曲目数必须实时反映当前资料库，不能卡在旧数字
- 实现：
  - `lib/data/daos/playlist_dao.dart`：`watchAllWithTrackCount()` 的统计 SQL 改为 `COUNT(t.id)` 并 `LEFT JOIN tracks t`，只计算仍存在于资料库中的歌曲；空歌单仍保留并显示 "0 首歌曲"
  - `lib/data/daos/track_dao.dart`：`deleteTrack()` 级联删除 `playlist_tracks` 中引用该曲目的关联记录，避免遗留孤儿数据
  - `lib/providers/artist_provider.dart`：艺术家分组已基于 `tracksProvider` 实时计算，曲目数自然随资料库变化；艺术家所有歌曲被删后自动从列表移除
- 验证：`build_runner` / `flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ✅ 第 24 步：点击正在播放的歌曲切换暂停/继续
- 需求：在歌曲列表/艺术家列表/歌单中点击当前正在播放的歌曲时，应暂停；再次点击则继续播放，而不是从头播放
- 实现：
  - `lib/services/audio_player_service.dart`：`playTracks()` 增加 `toggleIfCurrent` 参数（默认 `true`）。若目标曲目 id 与当前播放曲目相同，调用 `togglePlay()` 切换播放/暂停；否则按原逻辑加载并播放
  - `lib/screens/library/artist_detail_screen.dart`：「播放全部」调用 `playTracks(..., toggleIfCurrent: false)`，确保点击播放全部时始终从头播放该艺术家曲目
  - `lib/screens/library/playlist_detail_screen.dart`：「播放全部」同样传入 `toggleIfCurrent: false`
- 验证：`build_runner` / `flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ✅ 第 25 步：设置页加入清除缓存功能
- 需求：检查产品使用过程中是否会产生缓存，若有则在设置中加入清除缓存功能并写明提示
- 分析：本地音乐播放器运行中主要产生以下可清理缓存
  - 应用缓存目录（`getApplicationCacheDirectory()`）中的临时文件
  - Flutter 图片缓存（内存）
  - just_audio 播放缓冲（通过停止播放器释放）
  - 已导入的歌曲、封面、数据库、歌单数据属于用户资料，不会被清除
- 实现：
  - 新增 `lib/services/cache_service.dart`：单例 `CacheService`，提供 `clearCache()`
    - 停止播放器释放音频缓冲
    - 清空 Flutter `imageCache`
    - 递归清理应用缓存目录内容并统计释放字节数
    - 提供 `formatSize()` 用于友好显示
  - `lib/screens/home/home_screen.dart`：设置页（`_buildSettingsPage`）新增「清除缓存」列表项
    - 点击弹出确认对话框，提示"将清除临时缓存（播放缓冲、图片缓存等），不会删除已导入的歌曲、歌单和设置"
    - 确认后调用 `CacheService.clearCache()`，完成后通过 SnackBar 显示释放空间或失败提示
- 验证：`build_runner` / `flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ✅ 第 26 步：搜索功能（本地 + 外部平台跳转）
- 需求：搜索已导入的歌曲/艺术家/歌单；本地无匹配时跳转到外部音乐平台继续搜索。不实现下载（外部平台无合法下载 API，绕 DRM 违法，已与用户确认砍掉）
- 实现：
  - `pubspec.yaml`：新增 `url_launcher: ^6.3.1`
  - `lib/providers/search_provider.dart`：新建 `SearchResults`（tracks/artists/playlists 聚合）+ `searchResultsProvider`（FutureProvider.family）；歌曲走 `TrackRepository.search()`（DB LIKE），艺术家对 `artistsProvider` 内存 `contains` 过滤，歌单对 `playlistsProvider` 内存按名过滤
  - `lib/screens/search/search_screen.dart`：新建搜索页
    - 圆角填充搜索框（300ms 防抖、清除按钮、autofocus）
    - 空查询：显示本地搜索引导提示
    - 有查询：分区展示「歌曲/艺术家/歌单」，每区带标题+计数；歌曲点击播放整组结果、长按/编辑/加入歌单复用 `TrackListTile`；艺术家→`ArtistDetailScreen`；歌单→`PlaylistDetailScreen`
    - 始终显示「在网上搜索」区，提供 4 个 `ActionChip`：网易云 / QQ音乐 / Apple Music / Spotify，点击 `launchUrl`（默认 mode，由系统自行选处理器：有 App 交 App，否则默认浏览器）跳转对应平台搜索 URL；失败 SnackBar 兜底
    - 本地无结果时显示「本地未找到匹配结果」引导，仍可跳转外部平台
  - `home_screen.dart`：底部导航第 3 项「搜索」body 由 placeholder 替换为 `SearchScreen`
  - `macos/Runner/{DebugProfile,Release}.entitlements`：补 `com.apple.security.network.client=true`（App Sandbox 下 `launchUrl` 出站网络访问必需，否则 macOS 点击平台 Chip 无反应）
- 验证：`flutter pub get` 通过；`flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ⚠️ 第 26 步补充：url_launcher 在 macOS 的构建环境限制
- 现象：点击外部平台 Chip 报 `PlatformException(channel-error, ...UrlLauncherApi.launchUrl)`，跳转不生效
- 根因（非代码问题）：
  - Flutter 3.44 将 macOS 插件默认改为 SwiftPM 集成；生成的 `macos/Flutter/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift` 为空（dependencies 空），`url_launcher_macos` 未被聚合，运行时 method channel 不存在
  - xcodebuild 解析 SwiftPM 依赖需调 `sandbox_apply`，而 **Trae 沙箱环境禁止该系统调用** → `sandbox-exec: sandbox_apply: Operation not permitted`，当前沙箱终端无法完成 macOS 完整构建
- 代码侧已就绪（与本次跳转直接相关，均无需再改）：
  - `launchUrl` 默认 mode（系统自行选处理器），try-catch + 失败 SnackBar 兜底
  - `macos/Runner/{DebugProfile,Release}.entitlements` 已含 `com.apple.security.network.client=true`
  - `GeneratedPluginRegistrant.swift` 与 `MainFlutterWindow.swift` 注册链路完整
- 解决：**在 macOS 自带 Terminal（非 Trae 沙箱）执行 `cd music_pocket && flutter clean && flutter build macos --debug`**，让 SwiftPM 正常解析插件依赖并打包 entitlements。entitlements / 插件集成改动必须经完整重新构建才生效，hot-reload 不够
- 注意：不要试图在 pubspec 加 `config.enable-swift-package-manager: false` 回退——pbxproj 仍引用 SwiftPM 包时该配置不生效，且 CocoaPods 已进维护模式

## ✅ 第 27 步：键盘播放快捷键
- 需求：电脑上按空格暂停/继续；Command+← / Command+→ 切换上一首/下一首
- 实现：
  - `lib/screens/home/home_screen.dart`：`_HomeScreenState` 注册 `HardwareKeyboard` 全局按键 handler
    - 空格键：仅在当前焦点不是文本输入框时触发 `AudioPlayerService.instance.togglePlay()`（避免搜索框输入空格被拦截）
    - `Cmd + ←` 触发 `playPrevious()`
    - `Cmd + →` 触发 `playNext()`
  - handler 返回 `true` 表示已处理，阻止事件继续冒泡；未匹配事件返回 `false`
  - `dispose` 时移除 handler，避免泄漏
  - 修复：Command 修饰键判断由 `logicalKeysPressed.contains(LogicalKeyboardKey.meta)` 改为 `HardwareKeyboard.instance.isMetaPressed`，解决 macOS 上 Cmd+←→ 无响应问题
- 验证：`flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ✅ 第 27 步补充：随机播放模式下上一首也走随机
- 问题：切到随机播放后，`Cmd+←` 上一首仍是顺序播放（如当前第 5 首直接跳到第 4 首），与播放模式不一致
- 根因：`AudioPlayerService._getPrevIndex()` 只实现了顺序播放逻辑，未处理 `PlayMode.shuffle`
- 修复：
  - `lib/services/audio_player_service.dart` 的 `_getPrevIndex()` 增加 shuffle 分支
    - 若 `_shuffleHistory` 非空，弹出最后一个历史索引作为上一首（回退到之前播放过的曲目）
    - 若历史为空且曲目多于 1 首，随机选一个非当前索引的曲目
    - 若只有 1 首则返回 0
  - 保持原有顺序播放逻辑不变
  - `playPrevious()` 中原有的「当前播放超过 3 秒则先 seek 到开头」逻辑依然优先触发，shuffle 不破坏该体验
- 验证：`flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ✅ 第 27 步补充：禁用 Flutter 默认键盘焦点导航
- 问题：按方向键时焦点会在底部导航栏（资料库/播放列表/导入…）之间移动；按空格时可能激活当前选中的底栏按钮，导致歌曲没暂停反而切换页面
- 根因：Flutter 桌面端默认启用了 `DirectionalFocusIntent`（方向键移动焦点）和 `ActivateIntent`（空格/回车激活按钮），与自定义音乐快捷键冲突
- 修复：
  - `lib/app.dart`：在 `MaterialApp` 层传入自定义 `shortcuts`，覆盖方向键和空格的默认导航意图
    - 基于 `WidgetsApp.defaultShortcuts` 拷贝，保留 Tab/复制粘贴等其他默认快捷键
    - 将 `←/→/↑/↓` 和 `Space` 映射为 `DoNothingAndStopPropagationIntent`，彻底阻止默认焦点导航
  - 配合 `HomeScreen` 的 `HardwareKeyboard` 全局 handler，空格和 `Cmd+←/→` 仅用于音乐控制
- 验证：`flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ✅ 第 27 步补充：禁用 Flutter 默认键盘焦点导航（修复）
- 问题：用户反馈重启后仍能用方向键移动底部导航焦点，空格仍会激活选中的底栏按钮
- 根因：Flutter 默认方向键/空格导航用的是 `SingleActivator`，而之前代码用 `LogicalKeySet` 覆盖，键类型不匹配，没有真正覆盖默认映射
- 修复：
  - `lib/app.dart` 的 `MaterialApp.shortcuts` 改为用 `SingleActivator(LogicalKeyboardKey.arrowLeft/arrowRight/arrowUp/arrowDown/space)` 映射到 `DoNothingAndStopPropagationIntent`
  - 与 `WidgetsApp.defaultShortcuts` 中默认导航的 `SingleActivator` 类型一致，从而真正禁用方向键焦点移动和空格激活
- 验证：`flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ✅ 第 28 步：播放列表（与系统底层分离的待播队列）

设计决策（已与用户确认）：
- 底栏「播放列表」Tab = 实时待播队列页（全屏平铺）；mini player / 全屏播放页另提供底部抽屉入口
- **两层分离**：系统底层播放顺序（顺序/单曲/随机）始终兜底、永远能自动下一首且 next≠current（除非源仅 1 首/单曲循环）；播放列表是上层，只存用户主动加入的手动项
- 队列为空时按当前曲在源列表中的位置派生下一首（顺序=当前曲后一首、随机=去重随机、单曲=原位重播），不再从头开始
- 关闭 mini 播放器：仅丢弃当前曲、保留手动队列与源上下文
- 持久化范围 = 当前曲 + 手动队列 + 源上下文 + 播放模式，重启后底层仍可续播

核心实现：
- `lib/services/audio_player_service.dart` 重写为两层模型：
  - `_upNext` 只存 manual 项（不再自动填充/排除集）；`_advance` 优先播队首手动项，空则 `_deriveNextFromSource`
  - `_deriveNextFromSource`：以「当前曲在源中的位置」为基准派生（修复自动续播从头播放的 bug）
  - `addToQueue`（插队尾）/ `playNextTrack`（插队首）/ `removeFromQueue` / `reorderQueue`（拖拽不改 manual 性）/ `jumpToQueueItem` / `clearQueue`
  - `cyclePlayMode` 只翻转模式 + 重置 shuffle 池，不再碰队列
  - `stopPlayback()`（关 mini，留队列）/ `removeCurrentAndContinue()`（删当前曲后接播）
  - 持久化 `<appSupport>/play_queue.json`：当前曲 id、上下文、lastSourceIndex、manual 队列 ids、模式、history、shuffleRecent、positionMs
- `lib/providers/track_provider.dart`：新增 `playQueueProvider`（StreamProvider<PlayQueueSnapshot>）
- UI 组件：
  - `lib/widgets/player/play_queue_content.dart`（新）：共享内容（当前曲锁定 + manual 待播列表，`onReorderItem` 拖拽/删除/点按播放 + 播放模式切换按钮）
  - `lib/widgets/player/play_queue_sheet.dart`：底部抽屉薄壳复用上述内容
  - `lib/screens/player/play_queue_screen.dart`：底栏 Tab 全屏页
  - `lib/widgets/library/track_quick_actions.dart`（新）：长按曲目菜单 → 下一首 / 加入播放列表 / 加入歌单 / 编辑 / 删除
  - `lib/widgets/library/track_list_tile.dart`：改为 StatefulWidget，「作为下一首播放」按钮点击用 `AnimatedSwitcher` 切换 `playlist_play`↔`check_circle` 短暂动画反馈（已移除 SnackBar）
- 接线：`mini_player` / `player_screen` 新增队列入口（移除全屏页的收藏/分享/更多三点）；`library/artist/playlist/search` 长按菜单统一改 `TrackQuickActions`，每行新增可见的「作为下一首播放」按钮
- app.dart：`initState` 调用 `AudioPlayerService.init` 恢复；`WidgetsBindingObserver` 在生命周期 paused/inactive/hidden 时 `persistNow`
- DAO/Repo：`TrackDao.getAll()/getByIds()`、`TrackRepository.getById/getAll/getByIds`、`PlaylistRepository.getTrackIds`

## ✅ 第 29 步：播放器 UI 精简与反馈优化
- 移除全屏播放页的「收藏心形 / 分享 / 右上角三个点」三个冗余入口（产品定位：凡加入本地即喜欢的歌曲）
- 「作为下一首播放」成功反馈从 SnackBar 改为按钮自带 `AnimatedSwitcher` 动画（点击 0.7s 内显示对勾后回弹），快速连点不堆积
- 修复关 mini 后自动续播队列为空时下一首从头播放库的问题：派生基准改为当前曲在源中的位置
- 验证：`flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）

## ✅ 第 30 步：MiniPlayer 进度按实际播放时长绘制
- `lib/widgets/player/mini_player.dart`：进度条采用正在播放的音频引擎时长，不再使用可能不准确的导入元数据时长
- `lib/services/audio_player_service.dart`：切歌加载前清空上一首的缓存时长，避免进度条短暂沿用错误上限
- 迷你/完整播放器均改为拖动时仅本地预览、松手时只提交一次 seek，避免一轮拖动产生大量并发原生定位请求
- seek 成功或失败后都会清除本地拖动目标，恢复音频引擎位置；连续拖动时仅最后一次操作可更新界面
- 验证：`flutter analyze` 通过（仅 2 个预配置 assets 目录缺失警告）；`flutter test` 通过（4/4）

## ⚠️ 环境注意事项（更新到 AGENTS.md）
- 系统没有 Rust 工具链 → 不能用 `metadata_god`，已切到 `audio_metadata_reader`（纯 Dart）
- Windows 完整构建需开启系统 Developer Mode（用于 plugin symlinks）。`flutter test`/`flutter analyze` 不受影响
- 数据库文件位置：`getApplicationDocumentsDirectory()/music_pocket/music_pocket.db`
- 导入的音频副本：`<docs>/music_pocket/audio/<microsec>.<ext>`
- 提取的封面：`<docs>/music_pocket/covers/<microsec>.<ext>`


## ✅ 第 31 步：可靠识别重复导入
- `Tracks` 增加可空 `contentHash`，Drift schema 升级至 v3；迁移只新增列，不为旧数据添加唯一约束。
- `ContentHashService` 以流式 SHA-256 计算文件指纹；导入前补齐旧歌曲的空指纹，按内容而非路径跳过重复导入。指纹或旧文件读取失败会抛出，由既有导入统计计为失败。
- 新增 `track_repository_import_test.dart`：覆盖同路径、异路径同内容、同名不同内容、旧记录补齐、旧库已有重复记录，以及 v2→v3 数据迁移不丢失歌曲。
- 验证：`build_runner` 通过；`flutter test` 通过（9/9）；`flutter analyze` 仅保留已有的 2 个 assets 目录警告。

## ✅ 第 32 步：删除应用托管的音频与封面
- `Tracks` 新增 `originalCoverPath` / `customCoverPath`，schema 升级至 v4；导入后直接使用内嵌封面，自定义封面清除后恢复原始封面。
- 删除歌曲时仅清理应用托管音频及无引用封面；共享封面和外部原文件保留，文件清理失败时数据库歌曲记录不删除并提示用户。
- 替换或清除自定义封面后清理旧的无引用文件；删除当前歌曲前释放播放器文件句柄，并同步移出来源、队列和历史。
- `TrackDao.deleteTrack()` 在同一事务中清理歌单、分类关联和歌曲记录。
- 新增文件清理、共享引用、路径保护、失败保留、封面恢复、内嵌封面和 v3→v4 迁移测试。
- 验证：`build_runner` 通过；`flutter test` 通过（19/19）；`flutter analyze` 仅保留已有的 2 个 assets 目录警告。
