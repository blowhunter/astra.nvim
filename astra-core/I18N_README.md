# Astra.nvim 国际化 (i18n) 功能

## 概述

Astra.nvim 现在支持多语言界面，用户可以用自己的语言查看错误消息、状态信息和CLI输出。

## 支持的语言

- **英语 (English)** - `en`
- **中文 (Chinese)** - `zh`
- **日语 (Japanese)** - `ja`
- **韩语 (Korean)** - `ko`
- **西班牙语 (Spanish)** - `es`
- **法语 (French)** - `fr`
- **德语 (German)** - `de`
- **俄语 (Russian)** - `ru`

## 配置语言

### 方法1：通过配置文件

在 TOML 配置文件中添加 `language` 字段：

```toml
[sftp]
host = "example.com"
port = 22
username = "user"
password = "password"
remote_path = "/remote/path"
local_path = "/local/path"

# 设置语言 (可选)
language = "zh"  # 中文
```

### 方法2：通过环境变量

设置 `ASTRA_LANGUAGE` 环境变量：

```bash
export ASTRA_LANGUAGE=zh
```

### 方法3：系统自动检测

如果没有明确设置语言，系统会自动检测：
1. 首先检查 `ASTRA_LANGUAGE` 环境变量
2. 然后检查 `LANG` 环境变量
3. 最后默认使用英语

## 使用示例

### 1. 初始化配置（中文）

```bash
export ASTRA_LANGUAGE=zh
cargo run init --config my-config.json
```

输出：
```
配置已初始化在 my-config.json
```

### 2. 同步文件（日语）

```bash
export ASTRA_LANGUAGE=ja
cargo run sync --config my-config.json
```

输出：
```
ファイルをアップロード中: /path/to/file
同期が正常に完了しました
```

### 3. 检查状态（韩语）

```bash
export ASTRA_LANGUAGE=ko
cargo run status --config my-config.json
```

输出：
```
보류 중인 작업: 2
  업로드: /local/path -> /remote/path
```

## 自定义翻译

你可以创建自定义翻译文件来扩展或覆盖默认翻译：

### 1. 创建翻译文件

创建一个 JSON 文件，例如 `custom_translations.json`：

```json
{
  "messages": {
    "custom.welcome": {
      "English": "Welcome to my custom setup",
      "Chinese": "欢迎使用我的自定义设置",
      "Japanese": "私のカスタム設定へようこそ"
    },
    "custom.goodbye": {
      "English": "Goodbye!",
      "Chinese": "再见！",
      "Japanese": "さようなら！"
    }
  }
}
```

### 2. 在代码中使用自定义翻译

```rust
// 加载自定义翻译
let mut store = get_translation_store();
store.load_from_file("custom_translations.json").unwrap();

// 使用自定义翻译
let msg = t("custom.welcome", &language);
println!("{}", msg);
```

## 测试多语言功能

运行测试脚本来查看不同语言的输出：

```bash
cd /home/ethan/work/rust/astra.nvim/astra-core
./test_i18n.sh
```

## 开发者指南

### 添加新语言

1. 在 `i18n.rs` 中的 `Language` 枚举中添加新语言
2. 在 `from_str` 方法中添加语言代码解析
3. 在 `name` 和 `native_name` 方法中添加语言名称
4. 在 `load_default_translations` 方法中添加默认翻译

### 添加新翻译键

1. 在 `load_default_translations` 方法中添加新翻译
2. 确保为所有支持的语言提供翻译
3. 在代码中使用 `t()` 或 `t_format()` 函数调用翻译

### 最佳实践

1. **使用描述性的翻译键**：使用像 `cli.file_uploaded` 而不是 `msg1` 这样的键名
2. **提供参数化翻译**：使用 `t_format()` 支持参数替换，如 `"File {0} uploaded successfully"`
3. **保持一致性**：在整个应用中使用相同的翻译模式和术语
4. **测试所有语言**：确保新功能在所有支持的语言下都能正常工作

## 故障排除

### 翻译显示为英文

如果消息显示为英文而不是你设置的语言：

1. 检查语言代码是否正确
2. 确认配置文件中的 `language` 字段拼写正确
3. 验证环境变量是否正确设置
4. 查看是否有拼写错误

### 缺少翻译

如果某些消息没有翻译：

1. 检查该消息是否在默认翻译中
2. 考虑添加自定义翻译
3. 作为后备，系统会显示英文翻译

### 配置文件错误

如果配置文件无法加载：

1. 检查 JSON/TOML 语法是否正确
2. 确认语言字段使用正确的格式
3. 查看错误日志获取详细信息

## 未来计划

- [ ] 添加更多语言支持
- [ ] 实现运行时语言切换
- [ ] 支持用户自定义翻译文件
- [ ] 添加翻译验证工具
- [ ] 改进错误消息的翻译覆盖

## 贡献

欢迎为国际化功能做出贡献！你可以：

1. 添加新语言的翻译
2. 改进现有翻译
3. 报告翻译问题
4. 提出新功能建议

请确保遵循项目的代码风格和测试要求。