# Astra.nvim 配置文件样例

本目录包含Astra.nvim的各种配置文件样例，方便用户快速配置和使用。

## 配置文件优先级

Astra.nvim按以下优先级加载配置文件：

1. **TOML配置** - `.astra-settings/settings.toml` (推荐)
2. **传统Astra配置** - `astra.json`
3. **VSCode SFTP配置** - `.vscode/sftp.json` (兼容格式)

## 配置文件说明

### settings.toml (推荐)

这是Astra.nvim的原生配置格式，支持最完整的功能。

**使用方法：**
```bash
# 在你的项目根目录下创建配置目录
mkdir -p .astra-settings

# 复制样例配置文件
cp config_sample/settings.toml .astra-settings/

# 编辑配置文件
vim .astra-settings/settings.toml
```

### astra.json (传统格式)

传统的JSON配置格式，兼容早期版本。

**使用方法：**
```bash
# 复制样例配置文件到项目根目录
cp config_sample/astra.json .
```

### vscode-sftp.json (VSCode兼容)

兼容VSCode SFTP插件的配置格式。

**使用方法：**
```bash
# 创建VSCode配置目录
mkdir -p .vscode

# 复制样例配置文件
cp config_sample/vscode-sftp.json .vscode/sftp.json
```

## 快速开始

1. 选择合适的配置格式（推荐使用TOML格式）
2. 复制对应的样例文件到你的项目
3. 修改配置文件中的服务器信息、路径等
4. 在Neovim中运行 `:AstraConfigTest` 验证配置
5. 使用 `:AstraSync` 开始同步文件

## 注意事项

- 配置文件中的 `~` 符号会自动扩展为用户主目录
- 远程路径的 `~` 会根据用户类型正确处理（root用户为 `/root`，普通用户为 `/home/username`）
- 建议使用私钥认证以提高安全性
- 路径配置支持相对路径和绝对路径

## 配置验证

配置完成后，可以使用以下命令验证：

```vim
:AstraConfigTest
```

该命令会显示详细的配置解析结果，帮助确认配置是否正确。