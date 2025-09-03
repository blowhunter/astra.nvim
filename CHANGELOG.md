# Astra.nvim 变更日志

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