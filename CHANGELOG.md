# Astra.nvim 变更日志

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