# Astra.nvim SSH 认证问题解决方案

## 问题诊断

当前错误：`AuthenticationError("[Session(-16)] Unable to extract public key from private key file: Unable to open private key file")`

这个错误表明系统在尝试使用 SSH 密钥认证时无法访问私钥文件。

## 解决方案

### 方案一：使用密码认证（推荐用于测试）

1. **修改配置文件**：
```toml
[sftp]
host = "your-server.com"       # 替换为实际服务器地址
port = 22
username = "your-username"     # 替换为实际用户名
password = "your-password"     # 替换为实际密码
remote_path = "/remote/path"   # 替换为实际远程路径
local_path = "/local/path"     # 替换为实际本地路径
```

2. **确保服务器支持密码认证**：
   - 检查 SSH 服务器配置：`/etc/ssh/sshd_config`
   - 确保 `PasswordAuthentication yes` 已启用
   - 重启 SSH 服务：`sudo systemctl restart sshd`

### 方案二：修复 SSH 密钥认证

如果需要使用 SSH 密钥认证，请按以下步骤排查：

#### 1. 检查密钥文件存在
```bash
ls -la ~/.ssh/id_rsa
```

#### 2. 检查密钥文件权限
```bash
# 设置正确的文件权限
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 700 ~/.ssh
```

#### 3. 检查密钥格式
```bash
# 检查密钥格式
file ~/.ssh/id_rsa

# 如果不是 PEM 格式，可能需要转换
ssh-keygen -p -m PEM -f ~/.ssh/id_rsa
```

#### 4. 测试 SSH 连接
```bash
# 先用 ssh 命令测试连接
ssh -i ~/.ssh/id_rsa username@hostname

# 或者测试密码认证
ssh username@hostname
```

#### 5. 使用调试模式
```bash
ssh -v username@hostname
```

### 方案三：创建新的 SSH 密钥对

1. **生成新密钥**：
```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/astra_key -N ""
```

2. **将公钥复制到服务器**：
```bash
ssh-copy-id -i ~/.ssh/astra_key.pub username@hostname
```

3. **在配置中使用新密钥**：
```toml
[sftp]
host = "your-server.com"
username = "your-username"
private_key_path = "/home/user/.ssh/astra_key"
remote_path = "/remote/path"
local_path = "/local/path"
```

## 测试步骤

### 步骤1：测试基本 SSH 连接
```bash
# 测试密码认证
ssh username@hostname

# 测试密钥认证
ssh -i ~/.ssh/id_rsa username@hostname
```

### 步骤2：测试 astra-core 配置
```bash
# 测试配置加载
./astra-core config-test

# 测试连接状态
./astra-core status
```

### 步骤3：创建测试环境
```bash
# 创建测试目录
mkdir -p /tmp/test-remote /tmp/test-local

# 创建测试文件
echo "test content" > /tmp/test-local/test.txt
```

## 常见问题排查

### 问题1：权限被拒绝
**错误**：`Permission denied (publickey,password)`

**解决**：
- 检查用户名和密码是否正确
- 确保 SSH 服务器允许密码认证
- 检查密钥文件权限

### 问题2：连接超时
**错误**：`Connection timed out`

**解决**：
- 检查防火墙设置
- 确认端口是否正确
- 检查网络连接

### 问题3：主机密钥验证失败
**错误**：`Host key verification failed`

**解决**：
- 手动连接一次以接受主机密钥：`ssh username@hostname`
- 或在代码中禁用严格的主机密钥检查（不推荐）

## 推荐的工作流程

### 开发/测试环境
1. **使用密码认证**（简单快捷）
2. **本地服务器**（如 127.0.0.1）
3. **关闭自动同步**（避免意外操作）

### 生产环境
1. **使用 SSH 密钥认证**（更安全）
2. **配置防火墙规则**
3. **启用详细日志**（便于排查问题）

## 配置示例

### 示例1：开发环境配置
```toml
[sftp]
host = "127.0.0.1"
port = 22
username = "test"
password = "test123"
remote_path = "/tmp/remote"
local_path = "/tmp/local"

[sync]
auto_sync = false
sync_on_save = false
sync_interval = 30000
```

### 示例2：生产环境配置
```toml
[sftp]
host = "production-server.com"
port = 2222
username = "deploy"
private_key_path = "/home/user/.ssh/deploy_key"
remote_path = "/var/www/html"
local_path = "/home/user/project"

[sync]
auto_sync = true
sync_on_save = true
sync_interval = 60000
```

## 调试技巧

### 启用详细日志
```bash
export RUST_LOG=debug
./astra-core status
```

### 检查系统日志
```bash
# SSH 服务器日志
sudo journalctl -u sshd -f

# 系统认证日志
sudo tail -f /var/log/auth.log
```

### 测试工具
```bash
# 使用 sftp 命令测试
sftp -P 22 username@hostname

# 使用 scp 命令测试
scp -P 22 file.txt username@hostname:/tmp/
```

## 总结

1. **首选方案**：使用密码认证进行测试
2. **检查要点**：服务器地址、端口、用户名、密码
3. **权限检查**：确保 SSH 服务器允许密码认证
4. **测试步骤**：先测试基本 SSH 连接，再测试 astra-core

通过以上步骤，您应该能够解决 SSH 认证问题并成功使用 astra-core。