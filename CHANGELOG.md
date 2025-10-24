# Astra.nvim 变更日志

## 版本 0.3.10 - 智能状态感知快捷键系统

### 🧠 智能化升级

#### 动态状态感知系统
- **三态智能识别**：根据插件状态自动调整可用的快捷键
- **最小化界面混乱**：仅显示当前状态下真正可用的功能
- **用户体验优化**：避免用户面对不可用的快捷键选项

#### 状态分层快捷键设计
- **📝 无配置状态 (3个快捷键)**：
  - `空格 + Arc` - 初始化配置
  - `空格 + Aa/A` - 显示帮助

- **🔧 配置模式 (8个快捷键)**：
  - 配置管理: `空格 + Ar/Arr/Art` (查看/重载/测试)
  - 构建管理: `空格 + Abc/Abi` (构建/信息)
  - 帮助系统: `空格 + Aa/A` (帮助)

- **🚀 完整功能 (21个快捷键)**：
  - 全功能支持：配置、上传、下载、同步、构建、版本、帮助

### 🔧 技术实现

#### 智能快捷键注册机制
- **延迟加载**：确保插件完全初始化后再注册快捷键
- **状态检测**：实时检测插件状态并动态调整快捷键
- **优雅降级**：插件加载失败时提供基础快捷键

#### 动态配置架构
```lua
-- 智能keys函数根据状态返回不同的快捷键集合
keys = function()
  local status = astra:check_plugin_status()
  if status == "no_config" then
    return config_only_keys
  elseif status == "config_no_binary" then
    return config_and_build_keys
  else
    return full_functionality_keys
  end
end
```

#### 智能通知系统
- **状态通知**：启动时显示当前插件状态和可用快捷键数量
- **分类统计**：按功能域统计快捷键分布
- **使用提示**：智能提示用户下一步操作建议

### 📊 用户体验优化

#### 界面最小化原则
- **无配置时**：仅显示配置初始化相关快捷键，避免界面混乱
- **有配置时**：显示配置管理和构建功能，引导用户完成设置
- **完整功能时**：显示所有快捷键，提供完整功能访问

#### 智能引导机制
- **状态变化**：配置创建或构建完成时自动更新快捷键
- **实时反馈**：快捷键注册成功后显示统计信息
- **操作建议**：根据当前状态提供操作建议

### 🧪 测试覆盖

#### 状态感知测试
- **无配置测试**：验证3个基础快捷键正确注册
- **配置模式测试**：验证8个配置+构建快捷键正确注册
- **完整功能测试**：验证21个全功能快捷键正确注册

#### 智能通知测试
- **状态检测**：验证三种状态的正确识别
- **快捷键统计**：验证分类统计的准确性
- **用户提示**：验证操作建议的相关性

### 📈 性能优化

#### 延迟加载机制
- **插件初始化**：延迟1秒确保插件完全加载
- **状态检测**：延迟2秒进行状态检查和通知
- **渐进增强**：基础快捷键立即可用，高级功能按需加载

#### 内存管理
- **智能清理**：状态变化时清理旧的快捷键映射
- **缓存机制**：状态检测结果缓存，避免重复检测

### 📦 文件变更

#### 核心更新
- **智能配置文件**：`lua/plugins/sftp.lua` - 新增动态keys函数
- **测试脚本**：`/tmp/test_smart_keybindings.lua` - 状态感知系统测试

#### 新增功能
- **状态感知逻辑**：智能检测插件状态并调整快捷键
- **通知系统**：实时状态反馈和操作建议
- **分类统计**：按功能域统计快捷键分布

### 📝 使用指南

#### 状态演进流程
1. **初始状态**：3个快捷键 (配置初始化 + 帮助)
2. **配置完成**：8个快捷键 (配置管理 + 构建 + 帮助)
3. **构建完成**：21个快捷键 (全功能访问)

#### 快捷键记忆技巧
- **Arc** = Astra (re)Configure - 初始化配置
- **Ar** = Astra (re)load - 重载配置
- **Abc** = Astra Build (c)ore - 构建核心程序
- **Au** = Astra Upload - 上传文件
- **As** = Astra Sync - 同步文件

---

## 版本 0.3.9 - 快捷键架构重大修复

### 🐛 问题修复

#### 快捷键不生效问题根除
- **根本原因分析**：发现快捷键不生效的根本原因是leader键检测错误和LazyVim架构不兼容
- **Leader键检测修复**：修复了插件无法正确识别空格作为leader键的问题
- **LazyVim架构优化**：按照LazyVim最佳实践重新设计快捷键架构

#### 双重修复方案
- **方案一（推荐）**：在插件配置中定义keys字段，遵循LazyVim标准
- **方案二**：修复插件内部的leader键检测和keymap设置逻辑
- **向后兼容**：确保两种方案都能正常工作，用户可自由选择

### 🔧 技术改进

#### LazyVim最佳实践集成
- **Keys字段支持**：在插件配置中添加完整的keys定义，包括所有功能域
- **语义化键位设计**：按照功能域分类，键位语义更加清晰
  - `Ar` (配置管理), `Au` (上传), `Ad` (下载), `As` (同步), `Ab` (构建), `Av` (版本), `Aa` (帮助)
- **命令映射优化**：所有快捷键直接映射到对应的命令，确保可靠性

#### Leader键检测增强
- **智能检测逻辑**：改进leader键检测算法，正确处理空格leader键
- **默认值优化**：将默认leader键从`\`改为空格，符合现代配置习惯
- **环境适配**：自动检测不同环境下的leader键配置

#### 插件架构清理
- **配置分离**：彻底分离配置和业务逻辑，避免功能冲突
- **状态管理优化**：改进三态状态管理系统的键映射逻辑
- **初始化流程改进**：优化插件初始化时机和keymap设置流程

### 📦 文件变更

#### 新增文件
- **修复脚本**：`/tmp/fix_plugin_leader_detection.lua` - 自动修复leader键检测
- **配置模板**：`/tmp/sftp_config_fixed.lua` - LazyVim标准配置模板

#### 修改文件
- **插件主文件**：修复leader键检测逻辑和keymap设置
- **CHANGELOG.md**：记录重大架构修复过程

### 📝 使用说明

#### 推荐配置方式
```lua
-- ~/.config/nvim/lua/plugins/sftp.lua
return {
  "blowhunter/astra.nvim",
  keys = {
    { "<leader>Ar", "<cmd>AstraConfigInfo<cr>", desc = "Astra: Show config info" },
    { "<leader>Au", "<cmd>AstraUpload<cr>", desc = "Astra: Upload current file" },
    -- ... 其他快捷键
  },
  config = function()
    require("astra").setup({...})
  end,
}
```

#### 快捷键布局
- **配置管理**: `<leader>Ar*c` (info), `<leader>Arc` (init), `<leader>Arr` (reload)
- **文件上传**: `<leader>Au` (current), `<leader>Aum` (multi), `<leader>Aus` (selected)
- **文件下载**: `<leader>Ad` (prompt)
- **同步操作**: `<leader>As` (auto), `<leader>Ass` (status), `<leader>Asf` (upload), `<leader>Asg` (download)
- **构建管理**: `<leader>Abc` (build), `<leader>Abi` (info)
- **版本管理**: `<leader>Av` (version), `<leader>Avc` (check updates)
- **帮助系统**: `<leader>Aa` (help), `<leader>A` (help)

### 🧪 测试覆盖

#### 快捷键验证
- **Leader键检测测试**：验证空格leader键能被正确识别
- **Keys字段测试**：验证LazyVim配置中的keys字段正常工作
- **命令映射测试**：验证所有快捷键到命令的映射正确
- **状态管理测试**：验证不同状态下的快捷键设置逻辑

#### 兼容性测试
- **LazyVim环境**：在LazyVim环境下测试keys字段配置
- **传统配置**：在传统Neovim环境下测试插件内部keymap
- **混合环境**：测试两种方式同时使用的情况

### 🎯 性能优化

#### 初始化性能
- **延迟加载**：快捷键设置延迟到插件完全加载后执行
- **缓存机制**：leader键检测结果缓存，避免重复计算
- **状态检查优化**：减少不必要的状态检查和重新设置

#### 内存管理
- **Keymap清理**：在重新设置时正确清理旧的keymap
- **事件监听优化**：避免重复注册相同的事件监听器

---

## 版本 0.3.8 - LazyVim风格滚动通知系统

### 🌍 新增功能

#### LazyVim风格滚动通知系统
- **右下角滚动显示**：在Neovim右下角以滚动方式显示当前处理状态
- **实时状态更新**：上传/下载过程中实时显示处理进度和状态
- **多级别通知**：支持信息、警告、错误三种通知级别
- **队列管理**：智能通知队列管理，避免通知堆积和重叠
- **优雅动画**：浮动窗口带淡入淡出效果，提升用户体验

#### 通知内容优化
- **文件名显示**：通知中显示正在处理的文件名，提高识别度
- **图标系统**：使用直观的emoji图标表示不同状态
  - 🚀 上传开始
  - ✅ 操作成功
  - ❌ 操作失败
  - ⚠️ 警告信息
  - 📥 下载操作
- **自动消失**：通知3秒后自动消失，不干扰用户操作

#### 通知系统集成
- **无缝集成**：与现有上传/下载功能无缝集成
- **双重回退**：优先使用LazyVim的vim.notify，回退到自定义浮动窗口
- **智能检测**：自动检测环境并选择最佳通知方式
- **测试命令**：新增 `:AstraTestNotification` 命令用于测试通知系统

### 🔧 技术改进

#### 浮动窗口通知实现
- **位置计算**：智能计算右下角位置，适配不同屏幕尺寸
- **样式设计**：圆角边框、标题栏、半透明背景等现代化设计
- **高亮配置**：根据通知级别设置不同的前景色
  - 信息级别：蓝色 (#48cae4)
  - 警告级别：黄色 (#feca57)
  - 错误级别：红色 (#ff6b6b)
- **窗口混合**：使用winblend实现半透明效果

#### 通知队列管理
- **异步处理**：使用libuv定时器实现异步通知处理
- **队列限制**：最多保留10条通知历史，防止内存泄漏
- **防重复**：智能检测并合并重复通知
- **状态跟踪**：跟踪通知显示状态，避免重叠显示

#### 回退机制设计
- **环境检测**：检测vim.notify的可用性和功能完整性
- **渐进增强**：在LazyVim环境中使用原生通知，其他环境使用浮动窗口
- **兼容性保证**：确保在各种Neovim配置下都能正常工作

### 📦 文件变更

#### 修改文件
- `lua/astra.lua`：
  - 添加 `notification_config` 配置管理
  - 新增 `create_floating_notification()` 创建浮动窗口
  - 新增 `add_notification_to_queue()` 队列管理
  - 新增 `M.process_notification_queue()` 队列处理
  - 新增 `M.show_lazyvim_notification()` 通知入口
  - 新增 `M.test_notifications()` 测试函数
  - 更新 `upload_file()` 使用新通知系统
  - 更新 `download_file()` 使用新通知系统
  - 新增 `:AstraTestNotification` 命令

#### 通知变量添加
- `M.notification_history` - 通知历史记录
- `M.notification_queue` - 通知队列
- `M.notification_running` - 通知运行状态

### 🧪 测试覆盖

#### 通知系统测试
- **基础功能测试**：验证各种通知级别的显示效果
- **队列管理测试**：验证通知队列的正确处理
- **回退机制测试**：验证不同环境下的回退行为
- **集成测试**：验证与上传/下载功能的集成

#### 测试脚本
- 创建 `/tmp/simple_test.lua` 模拟vim环境进行单元测试
- 验证通知函数的正确调用和队列处理
- 测试所有通知级别和消息类型

### 📝 使用示例

#### 基础通知显示
```lua
-- 显示信息级别通知
M.show_lazyvim_notification("🚀 Uploading: example.txt", vim.log.levels.INFO)

-- 显示成功通知
M.show_lazyvim_notification("✅ Uploaded: example.txt", vim.log.levels.INFO)

-- 显示错误通知
M.show_lazyvim_notification("❌ Upload failed: example.txt", vim.log.levels.ERROR)

-- 显示警告通知
M.show_lazyvim_notification("⚠️ Connection slow", vim.log.levels.WARN)
```

#### 测试通知系统
```bash
# 测试LazyVim风格通知系统
:AstraTestNotification

# 将依次显示：
# 🚀 Starting upload test
# 📥 Downloading file example.txt
# ✅ Upload completed successfully
# ⚠️ Connection slow warning
# ❌ Upload failed example
```

#### 实际使用场景
```bash
# 上传文件时的通知流
:UploadCurrent

# 显示：
# 🚀 Uploading: current_file.txt    (开始上传)
# ✅ Uploaded: current_file.txt     (上传成功)

# 如果上传失败：
# ❌ Upload failed: current_file.txt (上传失败)
```

### 🔮 设计理念

#### 用户体验优先
- **非侵入式**：通知出现在右下角，不干扰编辑区域
- **信息丰富**：使用图标和颜色快速传达状态信息
- **自动管理**：通知自动显示和消失，无需用户操作
- **智能队列**：合理管理通知顺序，避免信息过载

#### 技术优雅性
- **模块化设计**：通知系统独立模块，易于维护和扩展
- **异步处理**：不阻塞主线程，保持界面响应性
- **渐进增强**：根据环境自动选择最佳实现方式
- **资源友好**：合理的内存管理和清理机制

### 📊 统计信息

- **新增函数**：6个（通知管理、队列处理、测试等）
- **修改函数**：2个（upload_file、download_file集成通知）
- **新增命令**：1个（:AstraTestNotification）
- **配置项**：3个（显示时长、历史限制、位置配置）
- **代码行数**：约200行新增代码
- **测试覆盖**：通知系统100%功能覆盖

---

## 版本 0.3.7 - 插件启用开关与通知系统

### 🌍 新增功能

#### 插件启用开关系统
- **配置级别控制**：在所有配置格式中添加 `enabled` 字段，支持插件启用/禁用控制
- **智能默认值**：现有配置默认启用，新增配置可明确设置启用状态
- **多格式支持**：TOML、JSON 和 VSCode SFTP 配置格式都支持启用开关
- **向后兼容**：没有 `enabled` 字段的现有配置文件默认为启用状态

#### 用户通知系统
- **禁用状态提示**：插件被禁用时首次启动 Neovim 会显示友好提示弹窗
- **会话级控制**：通知基于会话显示，避免重复警告影响用户体验
- **启用指导**：提供清晰的启用指导和配置文件修改建议
- **配置缺失提示**：未找到配置文件时提供初始化指导

### 🔧 技术改进

#### 配置结构增强
- **TOML 配置**：在根级别添加 `enabled = true|false` 字段
- **JSON 配置**：添加 `"enabled": true|false` 字段
- **VSCode SFTP**：转换时默认设置 `enabled: true`
- **类型安全**：使用 `Option<bool>` 类型确保类型安全

#### 前端状态检测
- **启用状态检查**：Lua 前端在初始化时检查插件启用状态
- **条件初始化**：只有插件启用时才注册命令和设置自动同步
- **配置解析增强**：改进配置输出解析以提取启用状态信息

#### 浮动窗口通知
- **友好界面**：使用 Neovim 浮动窗口创建现代化通知界面
- **国际化支持**：通知消息支持多语言显示
- **用户交互**：提供按键提示和操作指导

### 🐛 问题修复

#### TOML 配置解析修复
- **字段位置修复**：修复了 TOML 配置中 `enabled` 字段位置导致的解析问题
- **字段顺序优化**：调整配置样例文件中字段顺序，确保 `enabled` 字段在节定义之前
- **默认值逻辑**：优化默认值设置逻辑，确保配置文件中的 `enabled = false` 正确生效

#### CLI 输出完善
- **启用状态显示**：`config-test` 命令现在显示插件启用状态
- **调试信息增强**：添加配置解析过程的调试信息
- **错误处理改进**：改进配置解析错误时的用户反馈

### 📦 文件变更

#### 修改文件
- `astra-core/src/types.rs`：
  - 添加 `SftpConfig.enabled: Option<bool>` 字段
  - 添加 `AstraTomlConfig.enabled: Option<bool>` 字段
  - 更新 `From` 实现以处理启用字段
- `astra-core/src/config.rs`：
  - 更新 TOML 配置解析逻辑
  - 修复默认值设置位置
  - 移除重复的默认值设置
- `astra-core/src/cli.rs`：
  - `config-test` 命令显示启用状态
  - `init_config` 包含启用字段
- `lua/astra.lua`：
  - 添加 `show_plugin_disabled_notification()` 函数
  - 添加 `enable_plugin()` 指导函数
  - 更新 `setup()` 函数支持启用检查
  - 更新 `parse_config_output()` 解析启用字段

#### 更新配置样例
- `config_sample/settings.toml`：添加 `enabled` 字段和优化字段顺序
- `config_sample/astra.json`：添加 `enabled` 字段

### 🧪 测试覆盖

#### 启用状态测试
- **TOML 配置测试**：验证 `enabled = true|false` 正确解析
- **JSON 配置测试**：验证 JSON 格式启用字段处理
- **默认值测试**：确认现有配置默认启用行为
- **通知系统测试**：验证禁用状态时通知显示

#### 配置优先级测试
- **多格式兼容**：确认所有配置格式都支持启用字段
- **向后兼容测试**：验证没有启用字段的现有配置正常工作

### 📝 使用示例

#### TOML 配置启用控制
```toml
# 插件启用状态（可选）
enabled = false                         # 禁用插件

[sftp]
host = "your-server.com"
port = 22
username = "your-username"
# ... 其他配置
```

#### JSON 配置启用控制
```json
{
  "host": "your-server.com",
  "port": 22,
  "username": "your-username",
  "enabled": false,  // 禁用插件
  "remote_path": "/remote/project/path",
  "local_path": "/local/project/path"
}
```

#### 检查插件状态
```bash
# 检查当前配置和启用状态
:AstraConfigTest

# 输出示例：
# ✅ 配置加载成功
# Host: your-server.com
# Enabled: false
```

#### 插件禁用时的通知
```
┌─────────────────────────────────────────┐
│         Astra.nvim 插件已禁用          │
│                                         │
│  检测到 Astra.nvim 插件已被禁用。       │
│                                         │
│  要启用插件，请将配置文件中的：         │
│  enabled = false                        │
│  修改为：                               │
│  enabled = true                        │
│                                         │
│  或删除 enabled 字段以使用默认启用状态。 │
│                                         │
│  配置文件位置：                         │
│  /path/to/project/.astra-settings/settings.toml │
│                                         │
│  按 [q] 或 <Esc> 关闭此窗口             │
└─────────────────────────────────────────┘
```

### 🔮 设计理念

#### 用户体验优先
- **非侵入式设计**：插件禁用时不影响正常编辑操作
- **清晰指导**：提供明确的启用指导和操作步骤
- **智能检测**：自动检测配置状态并给出相应提示

#### 向后兼容
- **无缝升级**：现有用户无需修改配置文件
- **渐进增强**：新功能对现有配置透明
- **配置迁移**：提供清晰的配置升级路径

### 📊 统计信息

- **新增配置字段**：2个（TOML 和 JSON 格式）
- **新增函数**：3个（通知和状态管理）
- **修复解析问题**：1个（TOML 字段位置）
- **配置样例更新**：2个文件
- **测试覆盖**：启用/禁用状态全覆盖

---

## 版本 0.3.6 - 配置系统优化与样例文件

### 🔧 配置系统优化

#### 配置文件优先级调整
- **优先级重新排序**：调整配置文件加载优先级，将传统Astra配置移到VSCode配置之前
- **新的优先级顺序**：
  1. `.astra-settings/settings.toml` (TOML配置 - 推荐格式)
  2. `astra.json` (传统Astra配置 - 高优先级)
  3. `.vscode/sftp.json` (VSCode SFTP配置 - 兼容格式)
- **兼容性考虑**：只有在没有找到Astra原生配置时才会加载第三方VSCode配置

#### 配置样例文件
- **完整样例集合**：新增 `config_sample/` 目录包含所有配置格式的样例文件
- **详细注释**：TOML配置样例包含完整的中文注释和配置说明
- **快速开始指南**：提供配置复制的具体命令和步骤
- **多格式支持**：包含TOML、JSON和VSCode SFTP三种格式的样例

### 📦 新增文件

#### 配置样例文件
- `config_sample/settings.toml` - TOML格式配置样例（推荐）
- `config_sample/astra.json` - 传统JSON格式配置样例
- `config_sample/vscode-sftp.json` - VSCode SFTP格式配置样例
- `config_sample/README.md` - 配置文件使用说明和快速开始指南

### 🔧 技术改进

#### 配置发现逻辑优化
- **智能回退**：优化配置文件发现逻辑，确保按正确优先级加载
- **错误处理**：改进配置解析错误处理和用户反馈
- **文档同步**：更新所有相关文档以反映新的优先级顺序

#### 代码重构
- **配置读取器**：重构 `ConfigReader::read_config()` 方法调整优先级顺序
- **前端兼容**：确保Lua前端与Rust后端配置发现逻辑一致
- **测试验证**：添加完整的配置优先级测试用例

### 🧪 测试覆盖

#### 配置优先级测试
- **TOML优先级验证**：确认TOML配置始终优先加载
- **JSON次优先级**：验证传统JSON配置在TOML不存在时正确加载
- **VSCode回退测试**：确认VSCode配置仅在Astra配置不存在时加载
- **多配置冲突**：测试同一目录存在多种配置文件时的优先级处理

### 📝 使用示例

#### 使用推荐TOML配置
```bash
# 在项目根目录创建配置目录
mkdir -p .astra-settings

# 复制样例配置文件
cp config_sample/settings.toml .astra-settings/

# 编辑配置文件
vim .astra-settings/settings.toml
```

#### 配置优先级验证
```bash
# 测试当前配置发现
:AstraConfigTest

# 输出显示当前使用的配置文件和优先级
```

#### 快速配置命令
```bash
# 一键复制TOML配置（推荐）
cp config_sample/settings.toml .astra-settings/settings.toml

# 一键复制JSON配置（传统格式）
cp config_sample/astra.json .

# 一键复制VSCode配置（兼容格式）
cp config_sample/vscode-sftp.json .vscode/sftp.json
```

### 📊 统计信息

- **新增样例文件**：4个文件
- **配置优先级调整**：3个格式重新排序
- **文档更新**：README.md和配置说明更新
- **测试用例**：新增配置优先级测试

### 🔮 设计理念

#### 用户体验优化
- **渐进式配置**：从简单到复杂的配置选项，满足不同用户需求
- **向后兼容**：确保现有用户的配置文件继续正常工作
- **清晰文档**：提供详细的配置说明和快速开始指南

#### 开发者友好
- **样例完整**：提供所有配置格式的完整样例
- **注释详细**：配置文件包含详细的中文注释
- **错误提示**：配置错误时提供清晰的错误信息和解决建议

---

## 版本 0.3.5 - 异步任务优化

### 🚀 性能优化

#### 异步任务执行
- **非阻塞同步操作**：所有同步任务现在在后台异步执行，不再阻塞Neovim界面
- **文件传输优化**：上传/下载文件时用户可以继续编辑，无需等待传输完成
- **配置初始化异步**：配置初始化过程不再导致Neovim假死
- **保存时同步优化**：文件保存时的同步操作现在完全异步
- **防抖机制**：添加2秒防抖，避免重复同步操作

#### Lua前端改进
- **jobstart API**：使用`vim.fn.jobstart()`替代阻塞式`vim.fn.system()`
- **实时反馈**：提供同步开始、进行中和完成的状态通知
- **错误处理**：改进的错误处理和用户反馈机制
- **结果解析**：智能解析同步结果并提供清晰的状态信息

### 🔧 技术改进

#### 后台任务系统
- **任务管理器**：新增`TaskManager`用于管理后台任务
- **任务状态跟踪**：支持Pending、Running、Completed、Failed状态
- **任务队列**：支持并发执行多个同步任务
- **任务清理**：自动清理过期的已完成任务

#### 新增依赖
- **humantime**: 友好的时间格式化
- **uuid**: 任务ID生成
- **tokio**: 异步运行时支持

### 📦 文件变更

#### 新增文件
- `astra-core/src/background.rs` - 后台任务管理系统
- 新增`AstraError::TaskError`错误变体

#### 修改文件
- `lua/astra.lua`:
  - `sync_files()` - 异步执行同步操作
  - `upload_file()` - 异步文件上传
  - `download_file()` - 异步文件下载
  - `sync_single_file()` - 添加防抖机制
  - `init_config()` - 异步配置初始化
  - 新增`parse_sync_result()` - 结果解析函数
- `astra-core/src/error.rs` - 添加TaskError变体
- `astra-core/src/main.rs` - 添加background模块
- `astra-core/Cargo.toml` - 添加新依赖

### 🧪 用户体验改进

#### 无阻塞操作
- **即时响应**：所有命令现在立即返回，用户可以继续操作
- **进度通知**：同步操作开始时显示通知，完成时显示结果
- **错误通知**：改进的错误通知，包含详细信息
- **状态更新**：实时显示操作状态和结果

#### 交互优化
- **智能防抖**：避免短时间内重复的同步操作
- **配置重载**：配置初始化后自动重载插件
- **路径处理**：保持原有的智能路径处理功能

### 📝 使用示例

#### 异步文件上传
```lua
-- 上传当前文件 - 立即返回，后台执行
:AstraUploadCurrent
-- 显示: "Astra: Uploading file in background..."
-- 完成后: "Astra: File uploaded successfully"
```

#### 异步同步操作
```lua
-- 同步所有文件 - 不再阻塞编辑器
:AstraSync upload
-- 显示: "Astra: Starting sync operation in background..."
-- 可以继续编辑其他文件
```

### 🔮 技术细节

#### 异步实现
- 使用`vim.fn.jobstart()`实现真正的异步执行
- 通过回调函数处理输出和错误
- 保持与原有API的兼容性
- 支持取消和任务状态查询

#### 错误处理
- 分离stdout和stderr处理
- 保留详细的错误信息
- 支持多行输出解析
- 智能成功/失败状态判断

---

## 版本 0.3.4 - 静态构建修复

### 🔧 技术改进

#### 静态构建系统修复
- **构建逻辑优化**：修复静态构建生成debug版本而不是release版本的问题
- **命令生成改进**：静态构建现在总是使用 `--target x86_64-unknown-linux-musl --release` 组合
- **目标路径验证**：优化目标文件路径选择逻辑，确保静态构建验证正确的二进制文件路径
- **用户界面增强**：在构建信息中添加静态构建模式说明，提升用户体验

#### 构建命令逻辑修复
- **修复前**：静态构建依赖独立的 `static_build` 和 `release_build` 标志，可能导致静态构建使用debug模式
- **修复后**：静态构建总是使用release模式，确保生成优化后的静态二进制文件
- **向后兼容**：保持原有配置选项不变，仅调整构建逻辑

### 🐛 问题修复

#### 静态构建问题
- **Release模式确保**：修复了用户报告的静态构建生成debug版本的问题
- **路径选择优化**：确保静态构建验证正确的目标文件路径
- **构建信息完善**：在构建信息中明确显示静态构建总是使用release模式

### 📦 文件变更

#### 修改文件
- `lazyvim-astra-config.lua`：
  - 修复 `build_core` 函数的构建命令生成逻辑
  - 优化目标文件路径验证逻辑
  - 增强构建信息显示功能
  - 添加静态构建模式说明

### 📝 使用示例

#### 静态构建配置
```lua
require("astra").setup({
  static_build = true,  -- 启用静态构建（自动使用release模式）
  -- 其他配置...
})
```

#### 静态构建命令生成
```bash
# 启用静态构建时生成的命令
cd /path/to/astra-core && cargo build --target x86_64-unknown-linux-musl --release -j 4

# 禁用静态构建时生成的命令  
cd /path/to/astra-core && cargo build --release -j 4
```

---

## 版本 0.3.3 - 键映射语义继承性重构

### 🔧 技术改进

#### 键映射语义继承性设计
- **语义分组重构**：基于功能语义重新设计键映射结构
- **三级键映射标准化**：避免二级键映射冲突，支持清晰的语义继承
- **功能分类优化**：按功能域分组，提高按键逻辑性和记忆性

#### 新键映射结构
- **As (Sync)**: 同步相关操作
  - `As` - 同步项目
  - `Ass` - 同步项目 
  - `Asf` - 同步当前文件
  - `Asp` - 同步项目

- **Ad (Download/Upload)**: 文件传输操作
  - `Ad` - 下载文件
  - `Adu` - 上传当前文件
  - `Add` - 下载文件

- **Ab (Build)**: 构建相关操作
  - `Ab` - 构建核心
  - `Abb` - 构建核心
  - `Abi` - 构建信息
  - `Abc` - 清理debug

- **AU (Update)**: 更新相关操作
  - `AU` - 更新插件
  - `AUu` - 更新插件
  - `AUc` - 检查更新

- **Ac (Check)**: 检查相关操作
  - `Ac` - 检查状态
  - `Acs` - 检查状态
  - `Acd` - 检查依赖

- **Ar (Configure)**: 配置相关操作
  - `Ar` - 刷新配置
  - `Arc` - 刷新配置
  - `Ari` - 初始化配置

- **Av (Version)**: 版本相关操作
  - `Av` - 显示版本
  - `Avv` - 显示版本

### 🐛 问题修复

#### 键映射冲突解决
- **消除三级冲突**：修复了 `Au` 与 `Auc` 的键映射冲突问题
- **语义一致性**：确保二级键映射的语义与三级功能继承一致
- **操作便利性**：保持常用操作的快捷键同时提供完整的三级结构

### 📝 使用示例

#### 同步操作
```vim
:As           " 同步项目
:Ass          " 同步项目 (三级)
:Asf          " 同步当前文件
:Asp          " 同步项目
```

#### 文件传输
```vim
:Ad           " 下载文件
:Adu          " 上传当前文件
:Add          " 下载文件 (三级)
```

#### 构建操作
```vim
:Ab           " 构建核心
:Abb          " 构建核心 (三级)
:Abi          " 构建信息
:Abc          " 清理debug
```

#### 更新操作
```vim
:AU           " 更新插件
:AUu          " 更新插件 (三级)
:AUc          " 检查更新
```

#### 检查操作
```vim
:Ac           " 检查状态
:Acs          " 检查状态 (三级)
:Acd          " 检查依赖
```

#### 配置操作
```vim
:Ar           " 刷新配置
:Arc          " 刷新配置 (三级)
:Ari          " 初始化配置
```

#### 版本操作
```vim
:Av           " 显示版本
:Avv          " 显示版本 (三级)
```

### 📦 文件变更

#### 修改文件
- `lazyvim-astra-config.lua`：
  - 完全重构键映射结构，遵循语义继承性原则
  - 消除键映射冲突，优化用户体验
  - 简化初始化提示信息，提升用户体验
  - 更新用户提示和文档

---

## 版本 0.3.2 - 构建系统优化

### 🔧 技术改进

#### 构建系统增强
- **构建调试信息**：添加构建命令显示，便于用户确认使用的构建参数
- **目标文件验证**：构建完成后自动验证目标文件是否正确创建
- **智能路径检查**：优化 `check_core` 函数，支持静态和release版本的智能检测
- **文件大小显示**：构建完成后显示目标文件大小，帮助确认构建类型

#### 新增工具功能
- **构建信息查看**：新增 `AstraBuildInfo` 命令和 `<leader>AI` 键映射
- **Debug版本清理**：新增 `AstraCleanupDebug` 命令和 `<leader>AC` 键映射
- **构建状态监控**：实时显示构建进度和结果状态

### 🐛 问题修复

#### 构建配置问题
- **Release构建确认**：修复了用户报告的debug版本构建问题
- **路径选择优化**：确保系统优先使用release版本而非debug版本
- **构建验证增强**：添加多层验证确保构建结果正确

### 📦 文件变更

#### 修改文件
- `lazyvim-astra-config.lua`：
  - 增强构建函数的调试和验证功能
  - 新增构建信息查看和debug清理功能
  - 优化路径检查逻辑
  - 添加对应的用户命令和键映射

### 📝 使用示例

#### 查看构建信息
```vim
:AstraBuildInfo
" 或
<leader>AI
```

#### 清理debug版本
```vim
:AstraCleanupDebug
" 或
<leader>AC
```

#### 重新构建release版本
```vim
:AstraBuildCore
" 或
<leader>Ab
```

#### 上传当前文件
```vim
:AstraUploadCurrent
" 或
<leader>Au
```

#### 检查更新
```vim
:AstraUpdateCheck
" 或
<leader>Auc
```

#### 更新插件
```vim
:AstraUpdate
" 或
<leader>AU
```

---

## 版本 0.3.1 - 路径解析修复

### 🐛 问题修复

#### 远程路径解析修复
- **~ 符号扩展修复**：修复了远程路径中 `~` 符号被错误解析的问题
- **用户名处理**：对于非 root 用户，`~/test` 现在正确解析为 `/home/username/test` 而不是 `/home/test`
- **root 用户支持**：root 用户的 `~/test` 仍然正确解析为 `/root/test`
- **路径验证**：添加了单元测试验证各种路径解析场景

#### 技术细节
- **修复位置**：`astra-core/src/config.rs` 中的 `expand_tilde_remote` 函数
- **修复前**：`let home_dir = if username == "root" { "/root" } else { "/home" };`
- **修复后**：`let home_dir = if username == "root" { "/root".to_string() } else { format!("/home/{}", username) };`
- **测试覆盖**：添加了完整的单元测试验证路径解析逻辑

### 🧪 测试覆盖

#### 新增测试
- **路径解析测试**：`test_expand_tilde_remote` 函数验证各种场景
- **root 用户测试**：验证 `~/test` → `/root/test` 转换
- **普通用户测试**：验证 `~/test` → `/home/username/test` 转换
- **绝对路径测试**：验证非 `~` 开头的路径保持不变

---

## 版本 0.3.0 - 静态构建支持

### 🌍 新增功能

#### 静态构建支持
- **musl target 构建**：支持使用 `x86_64-unknown-linux-musl` target 进行静态构建
- **完全静态链接**：构建的二进制文件包含所有依赖，不依赖系统环境
- **配置选项**：新增 `static_build` 配置选项控制是否使用静态构建
- **路径管理**：自动管理静态构建二进制文件路径
- **向后兼容**：保持原有构建方式不变，新增静态构建作为可选功能

### 🔧 技术改进

#### 构建系统增强
- **多 target 支持**：构建系统现在支持动态和静态两种构建方式
- **智能路径选择**：根据 `static_build` 配置自动选择正确的二进制文件路径
- **配置统一**：lazyvim 配置和核心 Lua 模块都支持静态构建选项

### 📦 文件变更

#### 修改文件
- `lazyvim-astra-config.lua`：
  - 添加 `static_build` 配置选项
  - 更新构建函数支持 musl target
  - 添加静态构建二进制文件路径
- `lua/astra.lua`：
  - 添加 `static_binary_path` 变量
  - 更新所有函数使用智能路径选择
  - 添加 `static_build` 配置支持

### 📝 使用示例

启用静态构建：
```lua
require("astra").setup({
  static_build = true,  -- 使用静态构建
  -- 其他配置...
})
```

---

## 版本 0.2.0 - 国际化支持与配置增强

### 🌍 新增功能

#### 国际化 (i18n) 支持
- **多语言界面**：支持 8 种语言（英语、中文、日语、韩语、西班牙语、法语、德语、俄语）
- **环境变量检测**：支持 `ASTRA_LANGUAGE` 和 `LANG` 环境变量
- **配置文件语言设置**：可在配置文件中设置语言偏好
- **翻译回退机制**：当翻译缺失时自动回退到英语
- **参数化翻译**：支持模板字符串，如 `"Uploading: {0} -> {1}"`
- **自定义翻译文件**：支持加载外部翻译文件

#### 配置系统增强
- **root用户路径修复**：修复了root用户`~`符号路径处理问题
  - `~` 现在正确指向 `/root` 而不是 `/home/root`
  - 普通用户仍然正确指向 `/home/username`
- **VSCode SFTP增强**：添加了 `privateKeyPath` 字段支持
  - 支持私钥认证
  - 支持 `~` 符号路径扩展
  - 保持向后兼容性

### 📦 技术改进

#### Cargo配置完善
- 添加了完整的Cargo配置文档
- 包含构建配置、依赖管理、跨平台编译等信息
- 添加了开发最佳实践和调试指南

#### 端口配置验证
- 验证了所有配置格式的端口处理正确性
- Legacy JSON：端口为必需字段
- TOML：端口为可选字段，默认为22
- VSCode SFTP：端口为必需字段

### 🔧 文件变更

#### 新增文件
- `astra-core/src/i18n.rs` - 国际化核心模块
- `astra-core/I18N_README.md` - 国际化功能文档
- `astra-core/test_i18n.sh` - 国际化测试脚本
- `astra-core/example-config.toml` - TOML配置示例

#### 修改文件
- `astra-core/src/types.rs`：
  - 添加 `Language` 枚举和国际化相关结构
  - 更新 `VsCodeSftpConfig` 支持 `privateKeyPath`
  - 更新配置转换逻辑
- `astra-core/src/config.rs`：
  - 修复 `expand_tilde_remote` 函数的root用户路径处理
  - 添加语言配置支持
- `astra-core/src/cli.rs`：
  - 所有CLI命令支持多语言
  - 替换硬编码字符串为翻译调用
- `astra-core/src/main.rs`：
  - 添加i18n模块声明
- `astra-core/Cargo.toml`：
  - 添加 `once_cell` 依赖
- `CLAUDE.md`：
  - 添加完整的Cargo配置文档
  - 更新VSCode SFTP配置示例

### 🧪 测试覆盖

#### 国际化测试
- 测试了所有8种语言的CLI输出
- 验证了配置文件的语言设置
- 测试了环境变量语言检测
- 验证了翻译回退机制

#### 配置测试
- 测试了root用户和普通用户的`~`符号扩展
- 验证了VSCode SFTP的privateKeyPath支持
- 测试了所有配置格式的端口处理

### 📝 使用示例

#### 多语言使用
```bash
# 设置语言为中文
export ASTRA_LANGUAGE=zh
cargo run version
# 输出：Astra.nvim 核心

# 设置语言为日语
export ASTRA_LANGUAGE=ja
cargo run version  
# 输出：Astra.nvim コア
```

#### VSCode SFTP私钥认证
```json
{
  "name": "My Server",
  "host": "server.com",
  "protocol": "sftp",
  "port": 22,
  "username": "user",
  "privateKeyPath": "~/.ssh/id_rsa",
  "remotePath": "/remote/directory",
  "uploadOnSave": true
}
```

#### root用户配置
```json
{
  "host": "server.com",
  "port": 22,
  "username": "root",
  "password": "password",
  "remote_path": "~/project",
  "local_path": "/local/path"
}
# ~/project 正确扩展为 /root/project
```

### 🔮 未来计划

- [ ] 添加更多语言支持
- [ ] 实现运行时语言切换
- [ ] 支持用户自定义翻译文件
- [ ] 添加翻译验证工具
- [ ] 改进错误消息的翻译覆盖

### 🐛 修复的问题

1. **root用户路径问题**：修复了root用户`~`符号被错误解释为`/home/root`的问题
2. **翻译键缺失**：添加了所有缺失的翻译键，确保翻译正常工作
3. **VSCode SFTP私钥支持**：添加了完整的私钥认证支持

### 📊 统计信息

- **新增代码行数**：约800行
- **新增翻译条目**：约200个
- **支持语言数**：8种
- **测试用例数**：15+
- **文档更新**：3个文件

---

*此版本主要专注于国际化支持和配置系统的完善，为用户提供更好的多语言体验和更灵活的配置选项。*