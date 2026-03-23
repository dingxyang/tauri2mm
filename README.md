# tauri2mm

基于 **Tauri 2 + React + TypeScript** 的多终端在线状态管理应用。  
项目通过 **Gitee Gist** 作为远程数据存储，结合 **高德地图** 可视化在线终端地理位置，支持桌面端与 Android 端运行。

## 核心能力

- 终端在线管理：Join / Exit 上下线，统一写入 Gitee Gist。
- 在线状态计算：基于 `status + last_update + onlineTimeoutMinutes` 判断计算在线。
- 终端信息展示：展示平台、型号、CPU、内存、GPS、更新时间。
- 地图分布可视化：仅展示在线且有 GPS 的终端点位（高德 JS API）。
- 设置与联通性测试：支持在设置页测试 Gitee / 高德配置是否可用。
- 本地缓存恢复：启动时优先读取本地缓存，拉取成功后回写缓存。

## 技术栈

- 前端：React 19、TypeScript、Vite 7
- 客户端：Tauri 2
- Tauri 插件：Geolocation、Opener
- Rust 侧：reqwest（访问 Gitee API）、serde/serde_json
- 地图：`@amap/amap-jsapi-loader`

## 目录结构

```text
tauri2mm/
├─ src/                    # React 前端
│  ├─ components/          # 页面组件（地图、设置页）
│  └─ lib/                 # 设备信息、Gitee 同步、存储、类型定义
├─ src-tauri/              # Tauri/Rust 后端与应用配置
│  ├─ src/lib.rs           # Tauri commands（设备ID、平台信息、Gitee读写）
│  └─ tauri.conf.json      # Tauri 构建配置
├─ dev-mac.sh              # macOS 开发启动
├─ dev-linux.sh            # Linux 开发启动
└─ dev-windows.cmd         # Windows 开发启动
```

## 快速开始

### 1) 环境准备

- Node.js（建议 LTS）
- pnpm
- Rust（`rustup` + `cargo`）
- Tauri 2 对应系统依赖（Linux 需额外安装 webkit 等依赖）

### 2) 安装依赖

```bash
pnpm install
```

### 3) 配置环境变量

复制并填写 `.env.example`：

```env
VITE_GITEE_ACCESS_TOKEN=
VITE_GITEE_GIST_ID=
VITE_GIST_FILE_NAME=app.json
VITE_AMAP_KEY=
VITE_AMAP_SECURITY_CODE=
VITE_REFRESH_SECONDS=10
VITE_ONLINE_TIMEOUT_MINUTES=60
```

说明：
- 若设置页填写了成对配置（Gitee: token+gistId；高德: key+securityCode），优先使用用户设置。
- 若未填写完整，回退使用 `.env` 配置。

## 本地开发

### 桌面端（推荐）

- macOS：`./dev-mac.sh`
- Linux：`./dev-linux.sh`
- Windows：`.\dev-windows.cmd`

也可以直接使用：

```bash
pnpm tauri dev
```

### 前端单独调试

```bash
pnpm dev
```

## Android 开发与打包

### 1) 初始化 Android 工程

```bash
pnpm tauri android init
```

### 2) Android 调试

```bash
pnpm tauri android dev
```

### 3) Android 构建

```bash
pnpm tauri android build
```

### 4) 签名配置

在 `src-tauri/gen/android/keystore.properties` 写入：

```properties
keyAlias=mytest
password=your_keystore_password
storeFile=/path/to/your-keystore.jks
```

生成 keystore 示例：

```bash
keytool -genkey -v -keystore ~/mytest-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias mytest
```

## 数据模型与同步机制

- 远程存储结构：`TerminalStore = { terminals: Record<string, TerminalInfo> }`
- 关键字段：`terminal_id / status / gps / last_update`
- 写入策略：采用“先拉取最新，再合并写回”避免覆盖其他终端更新
- 退出兜底：正常路径失败时，使用本地缓存进行离线状态回写
- 关闭拦截：Tauri 窗口关闭前触发 `app-closing`，尽量完成离线写入后再退出

## 构建命令

```bash
pnpm build
```

## GitHub Actions（Android Release）

工作流：`.github/workflows/release.yml`

需要配置的 Repository Secrets：

- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_BASE64`（keystore 文件 base64）
- `VITE_GITEE_ACCESS_TOKEN`
- `VITE_GITEE_GIST_ID`
- `VITE_AMAP_KEY`
- `VITE_AMAP_SECURITY_CODE`
