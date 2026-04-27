我来帮您实现一个跨平台的开机自启动管理库。以下是完整的Rust实现：

## Cargo.toml
```toml
[package]
name = "autostart-manager"
version = "0.1.0"
edition = "2021"

[dependencies]
# Windows依赖
[target.'cfg(windows)'.dependencies]
winreg = "0.50"
windows = { version = "0.54", features = [
    "Win32_Foundation",
    "Win32_System_Registry",
]}

# macOS依赖
[target.'cfg(target_os = "macos")'.dependencies]
plist = "1.5"
dirs = "5.0"

# Linux依赖
[target.'cfg(target_os = "linux")'.dependencies]
dirs = "5.0"
xdg = "2.5"
```

## 主库实现 (src/lib.rs)
```rust
use std::error::Error;
use std::path::{Path, PathBuf};

#[cfg(target_os = "windows")]
mod windows;
#[cfg(target_os = "macos")]
mod macos;
#[cfg(target_os = "linux")]
mod linux;

/// 跨平台自启动管理器
pub struct AutoStartManager {
    app_name: String,
    app_path: PathBuf,
    args: Vec<String>,
}

impl AutoStartManager {
    /// 创建新的自启动管理器
    pub fn new(app_name: &str, app_path: &Path) -> Self {
        Self {
            app_name: app_name.to_string(),
            app_path: app_path.to_path_buf(),
            args: Vec::new(),
        }
    }
    
    /// 设置启动参数
    pub fn with_args(mut self, args: Vec<&str>) -> Self {
        self.args = args.iter().map(|s| s.to_string()).collect();
        self
    }
    
    /// 启用开机自启动
    pub fn enable(&self) -> Result<(), Box<dyn Error>> {
        #[cfg(target_os = "windows")]
        return windows::enable_autostart(&self.app_name, &self.app_path, &self.args);
        
        #[cfg(target_os = "macos")]
        return macos::enable_autostart(&self.app_name, &self.app_path, &self.args);
        
        #[cfg(target_os = "linux")]
        return linux::enable_autostart(&self.app_name, &self.app_path, &self.args);
        
        #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
        return Err("Unsupported operating system".into());
    }
    
    /// 禁用开机自启动
    pub fn disable(&self) -> Result<(), Box<dyn Error>> {
        #[cfg(target_os = "windows")]
        return windows::disable_autostart(&self.app_name);
        
        #[cfg(target_os = "macos")]
        return macos::disable_autostart(&self.app_name);
        
        #[cfg(target_os = "linux")]
        return linux::disable_autostart(&self.app_name);
        
        #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
        return Err("Unsupported operating system".into());
    }
    
    /// 检查是否已启用自启动
    pub fn is_enabled(&self) -> Result<bool, Box<dyn Error>> {
        #[cfg(target_os = "windows")]
        return windows::is_autostart_enabled(&self.app_name, &self.app_path, &self.args);
        
        #[cfg(target_os = "macos")]
        return macos::is_autostart_enabled(&self.app_name);
        
        #[cfg(target_os = "linux")]
        return linux::is_autostart_enabled(&self.app_name);
        
        #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
        return Err("Unsupported operating system".into());
    }
}
```

## Windows实现 (src/windows.rs)
```rust
use std::error::Error;
use std::path::{Path, PathBuf};
use winreg::enums::*;
use winreg::RegKey;

pub fn enable_autostart(
    app_name: &str,
    app_path: &Path,
    args: &[String],
) -> Result<(), Box<dyn Error>> {
    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    let run_key = hkcu.open_subkey_with_flags(
        "Software\\Microsoft\\Windows\\CurrentVersion\\Run",
        KEY_SET_VALUE | KEY_READ,
    )?;
    
    // 构建完整的命令行
    let full_command = if args.is_empty() {
        format!("\"{}\"", app_path.display())
    } else {
        let args_str = args.join(" ");
        format!("\"{}\" {}", app_path.display(), args_str)
    };
    
    run_key.set_value(app_name, &full_command)?;
    Ok(())
}

pub fn disable_autostart(app_name: &str) -> Result<(), Box<dyn Error>> {
    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    let run_key = hkcu.open_subkey_with_flags(
        "Software\\Microsoft\\Windows\\CurrentVersion\\Run",
        KEY_SET_VALUE | KEY_READ,
    )?;
    
    if let Ok(_) = run_key.get_value::<String, _>(app_name) {
        run_key.delete_value(app_name)?;
    }
    
    Ok(())
}

pub fn is_autostart_enabled(
    app_name: &str,
    app_path: &Path,
    args: &[String],
) -> Result<bool, Box<dyn Error>> {
    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    let run_key = hkcu.open_subkey_with_flags(
        "Software\\Microsoft\\Windows\\CurrentVersion\\Run",
        KEY_READ,
    )?;
    
    match run_key.get_value::<String, _>(app_name) {
        Ok(current_value) => {
            let expected_value = if args.is_empty() {
                format!("\"{}\"", app_path.display())
            } else {
                let args_str = args.join(" ");
                format!("\"{}\" {}", app_path.display(), args_str)
            };
            Ok(current_value == expected_value)
        }
        Err(_) => Ok(false),
    }
}
```

## macOS实现 (src/macos.rs)
```rust
use std::error::Error;
use std::fs::{self, File};
use std::path::{Path, PathBuf};
use dirs::home_dir;
use plist::Value;

pub fn enable_autostart(
    app_name: &str,
    app_path: &Path,
    args: &[String],
) -> Result<(), Box<dyn Error>> {
    let plist_dir = home_dir()
        .ok_or("无法获取用户目录")?
        .join("Library")
        .join("LaunchAgents");
    
    fs::create_dir_all(&plist_dir)?;
    
    let plist_path = plist_dir.join(format!("com.{}.plist", app_name));
    
    // 构建参数数组
    let program_args = {
        let mut v = vec![app_path.to_str().ok_or("无效的应用路径")?.to_string()];
        v.extend_from_slice(args);
        v
    };
    
    // 创建plist内容
    let mut dict = plist::Dictionary::new();
    dict.insert("Label".to_string(), Value::String(format!("com.{}", app_name)));
    dict.insert("ProgramArguments".to_string(), Value::Array(
        program_args.into_iter().map(Value::String).collect()
    ));
    dict.insert("RunAtLoad".to_string(), Value::Boolean(true));
    dict.insert("KeepAlive".to_string(), Value::Boolean(false));
    
    let plist = Value::Dictionary(dict);
    plist.to_writer_xml(File::create(&plist_path)?)?;
    
    // 加载LaunchAgent
    let _ = std::process::Command::new("launchctl")
        .arg("load")
        .arg("-w")
        .arg(plist_path)
        .status();
    
    Ok(())
}

pub fn disable_autostart(app_name: &str) -> Result<(), Box<dyn Error>> {
    let plist_path = home_dir()
        .ok_or("无法获取用户目录")?
        .join("Library")
        .join("LaunchAgents")
        .join(format!("com.{}.plist", app_name));
    
    // 先尝试卸载
    let _ = std::process::Command::new("launchctl")
        .arg("unload")
        .arg("-w")
        .arg(&plist_path)
        .status();
    
    // 删除plist文件
    if plist_path.exists() {
        fs::remove_file(plist_path)?;
    }
    
    Ok(())
}

pub fn is_autostart_enabled(app_name: &str) -> Result<bool, Box<dyn Error>> {
    let plist_path = home_dir()
        .ok_or("无法获取用户目录")?
        .join("Library")
        .join("LaunchAgents")
        .join(format!("com.{}.plist", app_name));
    
    Ok(plist_path.exists())
}
```

## Linux实现 (src/linux.rs)
```rust
use std::error::Error;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use dirs::config_dir;
use xdg::BaseDirectories;

pub fn enable_autostart(
    app_name: &str,
    app_path: &Path,
    args: &[String],
) -> Result<(), Box<dyn Error>> {
    let xdg_dirs = BaseDirectories::with_prefix(app_name)?;
    
    // 获取或创建autostart目录
    let autostart_dir = xdg_dirs
        .place_config_file("autostart")
        .map_err(|_| "无法创建autostart目录")?;
    
    let desktop_entry_path = autostart_dir.join(format!("{}.desktop", app_name));
    
    // 构建Exec命令
    let exec_command = if args.is_empty() {
        format!("\"{}\"", app_path.display())
    } else {
        let args_str = args.join(" ");
        format!("\"{}\" {}", app_path.display(), args_str)
    };
    
    // 创建.desktop文件
    let mut file = File::create(&desktop_entry_path)?;
    writeln!(file, "[Desktop Entry]")?;
    writeln!(file, "Type=Application")?;
    writeln!(file, "Name={}", app_name)?;
    writeln!(file, "Exec={}", exec_command)?;
    writeln!(file, "Terminal=false")?;
    writeln!(file, "NoDisplay=false")?;
    writeln!(file, "X-GNOME-Autostart-enabled=true")?;
    
    Ok(())
}

pub fn disable_autostart(app_name: &str) -> Result<(), Box<dyn Error>> {
    let xdg_dirs = BaseDirectories::with_prefix(app_name)?;
    let desktop_entry_path = xdg_dirs
        .place_config_file("autostart")
        .map(|mut p| {
            p.push(format!("{}.desktop", app_name));
            p
        });
    
    if let Ok(path) = desktop_entry_path {
        if path.exists() {
            fs::remove_file(path)?;
        }
    }
    
    Ok(())
}

pub fn is_autostart_enabled(app_name: &str) -> Result<bool, Box<dyn Error>> {
    let xdg_dirs = BaseDirectories::with_prefix(app_name)?;
    let desktop_entry_path = xdg_dirs
        .place_config_file("autostart")
        .map(|mut p| {
            p.push(format!("{}.desktop", app_name));
            p
        });
    
    match desktop_entry_path {
        Ok(path) => Ok(path.exists()),
        Err(_) => Ok(false),
    }
}
```

## 使用示例 (src/main.rs 或 在你的应用中)
```rust
use autostart_manager::AutoStartManager;
use std::env;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 获取当前可执行文件路径
    let exe_path = env::current_exe()?;
    
    // 创建自启动管理器
    let autostart = AutoStartManager::new("MyApp", &exe_path)
        .with_args(vec!["--minimized"]);
    
    println!("当前自启动状态: {}", autostart.is_enabled()?);
    
    // 启用自启动
    match autostart.enable() {
        Ok(_) => println!("✓ 已启用开机自启动"),
        Err(e) => println!("✗ 启用失败: {}", e),
    }
    
    // 禁用自启动
    // match autostart.disable() {
    //     Ok(_) => println!("✓ 已禁用开机自启动"),
    //     Err(e) => println!("✗ 禁用失败: {}", e),
    // }
    
    Ok(())
}
```

## GUI应用示例 (使用Tauri)
```toml
# 在Cargo.toml中添加
[dependencies]
tauri = { version = "2.0", features = ["shell-open"] }
```

```rust
// src-tauri/src/main.rs
#[tauri::command]
fn enable_autostart(app_name: &str, enabled: bool) -> Result<(), String> {
    use autostart_manager::AutoStartManager;
    use std::env;
    
    let exe_path = env::current_exe()
        .map_err(|e| format!("获取可执行文件路径失败: {}", e))?;
    
    let autostart = AutoStartManager::new(app_name, &exe_path);
    
    if enabled {
        autostart.enable()
            .map_err(|e| format!("启用自启动失败: {}", e))
    } else {
        autostart.disable()
            .map_err(|e| format!("禁用自启动失败: {}", e))
    }
}

#[tauri::command]
fn is_autostart_enabled(app_name: &str) -> Result<bool, String> {
    use autostart_manager::AutoStartManager;
    use std::env;
    
    let exe_path = env::current_exe()
        .map_err(|e| format!("获取可执行文件路径失败: {}", e))?;
    
    let autostart = AutoStartManager::new(app_name, &exe_path);
    autostart.is_enabled()
        .map_err(|e| format!("检查自启动状态失败: {}", e))
}
```

## 使用说明

1. **添加库到你的项目**：
   ```bash
   cargo add autostart-manager
   ```

2. **基本用法**：
   ```rust
   use autostart_manager::AutoStartManager;
   use std::env;
   
   fn main() {
       let exe_path = env::current_exe().unwrap();
       let manager = AutoStartManager::new("MyApp", &exe_path);
       
       // 启用
       manager.enable().unwrap();
       
       // 禁用
       manager.disable().unwrap();
       
       // 检查状态
       let enabled = manager.is_enabled().unwrap();
   }
   ```

3. **权限说明**：
   - **Windows**: 不需要管理员权限（写入HKCU）
   - **macOS**: 需要用户权限
   - **Linux**: 不需要特殊权限

4. **注意事项**：
   - macOS上可能需要重启登录才能生效
   - Linux上不同的桌面环境可能有不同的自启动机制
   - 确保应用路径是正确的绝对路径

这个实现提供了完整的跨平台开机自启动管理功能，您可以根据需要集成到任何Rust桌面应用中。