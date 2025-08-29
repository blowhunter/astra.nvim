# Astra.nvim 完整故障排除指南

## 当前问题分析

### 错误信息
```
AuthenticationError("[Session(-16)] Unable to extract public key from private key file: Unable to open private key file")
```

### 问题原因
这个错误表明系统在尝试使用 SSH 密钥认证时无法访问或读取私钥文件。可能的原因包括：

1. **私钥文件不存在**
2. **私钥文件权限不正确**
3. **私钥格式不支持**
4. **SSH 配置问题**
5. **服务器认证设置问题**

## 立即解决方案

### 方案A：使用密码认证（最简单）

#### 1. 确认服务器支持密码认证
```bash
# 检查SSH服务器配置
sudo cat /etc/ssh/sshd_config | grep PasswordAuthentication

# 应该显示：PasswordAuthentication yes
```

#### 2. 修改 astra.nvim 配置
```toml
# ~/.astra-settings/settings.toml
[sftp]
host = "127.0.0.1"        # 您的服务器地址
port = 22
username = "test"            # 您的用户名
password = "test"            # 您的密码
remote_path = "/tmp/test"      # 远程目录
local_path = "/tmp/local"      # 本地目录

[sync]
auto_sync = false
sync_on_save = false
sync_interval = 30000
```

#### 3. 测试基本连接
```bash
# 先用ssh命令测试连接
ssh test@127.0.0.1

# 如果能连接，再测试astra-core
./astra-core config-test
```

### 方案B：修复SSH密钥认证

#### 1. 检查现有密钥
```bash
# 列出SSH密钥文件
ls -la ~/.ssh/

# 检查私钥权限（应该是600）
ls -la ~/.ssh/id_rsa

# 如果权限不正确，修复权限
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 700 ~/.ssh
```

#### 2. 测试密钥认证
```bash
# 使用ssh命令测试密钥认证
ssh -i ~/.ssh/id_rsa test@127.0.0.1

# 或者使用详细模式查看问题
ssh -v -i ~/.ssh/id_rsa test@127.0.0.1
```

#### 3. 生成新的密钥对（如果需要）
```bash
# 生成新密钥
ssh-keygen -t rsa -b 2048 -f ~/.ssh/astra_test_key -N ""

# 显示公钥（需要添加到服务器）
cat ~/.ssh/astra_test_key.pub

# 复制公钥到服务器（需要输入密码）
ssh-copy-id -i ~/.ssh/astra_test_key.pub test@127.0.0.1
```

#### 4. 在astra.nvim中使用新密钥
```toml
[sftp]
host = "127.0.0.1"
port = 22
username = "test"
private_key_path = "/home/user/.ssh/astra_test_key"
remote_path = "/tmp/test"
local_path = "/tmp/local"

[sync]
auto_sync = false
sync_on_save = false
sync_interval = 30000
```

## 完整测试流程

### 第一步：环境准备
```bash
# 创建测试目录
sudo mkdir -p /tmp/test-remote /tmp/test-local
sudo chmod 777 /tmp/test-remote /tmp/test-local

# 创建测试用户（如果需要）
sudo useradd -m test
sudo passwd test  # 设置密码为 "test"
```

### 第二步：SSH服务器配置
```bash
# 编辑SSH配置
sudo nano /etc/ssh/sshd_config

# 确保以下设置正确：
Port 22
PasswordAuthentication yes
PermitRootLogin no
PubkeyAuthentication yes

# 重启SSH服务
sudo systemctl restart sshd
```

### 第三步：测试SSH连接
```bash
# 测试密码认证
ssh test@127.0.0.1

# 如果成功，说明密码认证工作正常
# 如果失败，检查系统日志：
sudo journalctl -u sshd -n 50
```

### 第四步：配置astra.nvim
```bash
# 使用密码认证配置
cat > ~/.astra-settings/settings.toml << 'EOF'
[sftp]
host = "127.0.0.1"
port = 22
username = "test"
password = "test"
remote_path = "/tmp/test-remote"
local_path = "/tmp/test-local"

[sync]
auto_sync = false
sync_on_save = false
sync_interval = 30000
EOF
```

### 第五步：测试astra-core
```bash
# 进入astra.nvim目录
cd /path/to/astra.nvim/astra-core

# 测试配置加载
./target/debug/astra-core config-test

# 测试连接状态
timeout 15s ./target/debug/astra-core status
```

## 故障排查工具

### 1. 网络连接测试
```bash
# 测试端口是否开放
telnet 127.0.0.1 22

# 或使用netstat
netstat -tlnp | grep :22
```

### 2. SSH服务状态
```bash
# 检查SSH服务状态
sudo systemctl status sshd

# 查看SSH服务日志
sudo journalctl -u sshd -f
```

### 3. 系统认证日志
```bash
# 查看认证日志
sudo tail -f /var/log/auth.log

# 或查看系统日志
sudo journalctl -f -t sshd
```

### 4. 防火墙检查
```bash
# 检查防火墙状态
sudo ufw status

# 或检查iptables
sudo iptables -L
```

## 常见错误及解决

### 错误1：Connection refused
```
Error: Connection refused
```
**解决**：
- 检查SSH服务是否运行：`sudo systemctl status sshd`
- 检查端口是否正确
- 检查防火墙设置

### 错误2：Authentication failed
```
AuthenticationError("Authentication failed")
```
**解决**：
- 验证用户名和密码
- 检查账户是否被锁定
- 查看认证日志

### 错误3：Permission denied
```
Permission denied (publickey)
```
**解决**：
- 确保服务器允许密钥认证
- 检查密钥文件权限
- 确认公钥已添加到服务器

### 错误4：Timeout
```
Error: Connection timeout
```
**解决**：
- 检查网络连接
- 检查服务器地址是否正确
- 检查防火墙设置

## 快速检查清单

### 服务器端检查
- [ ] SSH服务正在运行
- [ ] 端口22（或指定端口）开放
- [ ] 密码认证已启用（如果使用密码）
- [ ] 用户账户存在且未锁定
- [ ] 远程目录存在且有写入权限

### 客户端检查
- [ ] 网络连接正常
- [ ] SSH配置文件权限正确
- [ ] 私钥文件权限为600（如果使用密钥）
- [ ] astra.nvim配置文件格式正确
- [ ] 本地目录存在且有写入权限

## 推荐的开发环境设置

### 使用Docker（推荐）
```dockerfile
# 创建简单的SSH测试服务器
docker run -d \
  --name ssh-test \
  -p 2222:22 \
  -e PASSWORD=test \
  -e USER_NAME=test \
  panubo/sshd
```

然后在astra.nvim配置中使用：
```toml
[sftp]
host = "127.0.0.1"
port = 2222
username = "test"
password = "test"
remote_path = "/home/test"
local_path = "/tmp/local"
```

### 使用本地SSH服务
如果您在本地测试，确保：
1. 系统SSH服务正在运行
2. 有一个测试用户账户
3. 知道正确的密码
4. 远程目录存在且有权限

## 总结

1. **首选方案**：使用密码认证进行测试（最简单）
2. **关键检查**：SSH服务状态、用户账户、密码、文件权限
3. **测试顺序**：先测试基本SSH连接，再测试astra-core
4. **调试工具**：使用`ssh -v`查看详细连接信息
5. **日志查看**：检查`/var/log/auth.log`和SSH服务日志

按照以上步骤，您应该能够成功解决SSH认证问题并使用astra-core进行文件同步。