use std::ffi::{CStr, CString};
use std::fs;
use std::os::raw::c_char;
use std::ptr;
use serde::{Deserialize, Serialize};
use serde_json;

#[derive(Serialize, Deserialize)]
struct FileInfo {
    name: String,
    size: u64,
    path: String,
}

/// 获取用户目录下的filecat文件夹路径，如果不存在则创建
#[no_mangle]
pub extern "C" fn get_filecat_path() -> *mut c_char {
    let home_dir = match dirs::home_dir() {
        Some(dir) => dir,
        None => return create_error_response("Failed to get home directory"),
    };
    
    let filecat_path = home_dir.join("filecat");
    
    // 如果文件夹不存在，则创建
    if !filecat_path.exists() {
        if let Err(e) = fs::create_dir_all(&filecat_path) {
            return create_error_response(&format!("Failed to create filecat directory: {}", e));
        }
    }
    
    let path_str = match filecat_path.to_str() {
        Some(s) => s,
        None => return create_error_response("Invalid path encoding"),
    };
    
    create_data_response(path_str)
}

/// 列出目录内容
#[no_mangle]
pub extern "C" fn list_directory(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::read_dir(path_str) {
        Ok(entries) => {
            let mut items: Vec<serde_json::Value> = Vec::new();
            
            for entry in entries {
                if let Ok(entry) = entry {
                    let path = entry.path();
                    let name = path.file_name()
                        .map(|n| n.to_string_lossy().to_string())
                        .unwrap_or_default();
                    
                    let is_dir = path.is_dir();
                    let size = if is_dir { 
                        0 
                    } else {
                        fs::metadata(&path).map(|m| m.len()).unwrap_or(0)
                    };
                    
                    items.push(serde_json::json!({
                        "name": name,
                        "is_dir": is_dir,
                        "size": size,
                        "path": path.to_string_lossy().to_string()
                    }));
                }
            }
            
            // 排序：文件夹在前，然后按名称排序
            items.sort_by(|a, b| {
                let a_is_dir = a["is_dir"].as_bool().unwrap_or(false);
                let b_is_dir = b["is_dir"].as_bool().unwrap_or(false);
                
                match (a_is_dir, b_is_dir) {
                    (true, false) => std::cmp::Ordering::Less,
                    (false, true) => std::cmp::Ordering::Greater,
                    _ => a["name"].as_str().unwrap_or("")
                        .cmp(&b["name"].as_str().unwrap_or(""))
                }
            });
            
            match serde_json::to_string(&items) {
                Ok(json_str) => create_data_response(&json_str),
                Err(e) => create_error_response(&format!("Serialization error: {}", e)),
            }
        },
        Err(e) => create_error_response(&format!("Failed to read directory: {}", e)),
    }
}

/// 创建文件
#[no_mangle]
pub extern "C" fn create_file(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::write(path_str, b"") {
        Ok(_) => create_success_response("File created successfully"),
        Err(e) => create_error_response(&format!("Failed to create file: {}", e)),
    }
}

/// 读取文件内容
#[no_mangle]
pub extern "C" fn read_file(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::read_to_string(path_str) {
        Ok(content) => create_data_response(&content),
        Err(e) => create_error_response(&format!("Failed to read file: {}", e)),
    }
}

/// 写入文件内容
#[no_mangle]
pub extern "C" fn write_file(path: *const c_char, content: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    if content.is_null() {
        return create_error_response("Content pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    let content_str = unsafe { 
        match CStr::from_ptr(content).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in content"),
        }
    };
    
    match fs::write(path_str, content_str.as_bytes()) {
        Ok(_) => create_success_response("File written successfully"),
        Err(e) => create_error_response(&format!("Failed to write file: {}", e)),
    }
}

/// 获取文件信息
#[no_mangle]
pub extern "C" fn get_file_info(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::metadata(path_str) {
        Ok(metadata) => {
            let file_info = FileInfo {
                name: get_filename_from_path(path_str),
                size: metadata.len(),
                path: path_str.to_string(),
            };
            
            match serde_json::to_string(&file_info) {
                Ok(json_str) => create_data_response(&json_str),
                Err(e) => create_error_response(&format!("Serialization error: {}", e)),
            }
        },
        Err(e) => create_error_response(&format!("Failed to get file info: {}", e)),
    }
}

/// 删除文件
#[no_mangle]
pub extern "C" fn delete_file(path: *const c_char) -> *mut c_char {
    if path.is_null() {
        return create_error_response("Path pointer is null");
    }
    
    let path_str = unsafe { 
        match CStr::from_ptr(path).to_str() {
            Ok(s) => s,
            Err(_) => return create_error_response("Invalid UTF-8 in path"),
        }
    };
    
    match fs::remove_file(path_str) {
        Ok(_) => create_success_response("File deleted successfully"),
        Err(e) => create_error_response(&format!("Failed to delete file: {}", e)),
    }
}

/// 获取文件名从完整路径
fn get_filename_from_path(path: &str) -> String {
    path.split('/').last().unwrap_or(path).split('\\').last().unwrap_or(path).to_string()
}

/// 辅助函数：创建成功响应
fn create_success_response(message: &str) -> *mut c_char {
    let response = format!("{{\"success\":true,\"message\":\"{}\"}}", message);
    match CString::new(response) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// 辅助函数：创建错误响应
fn create_error_response(message: &str) -> *mut c_char {
    let response = format!("{{\"success\":false,\"message\":\"{}\"}}", message);
    match CString::new(response) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// 辅助函数：创建数据响应
fn create_data_response(data: &str) -> *mut c_char {
    let response = format!("{{\"success\":true,\"data\":\"{}\"}}", data);
    match CString::new(response) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => ptr::null_mut(),
    }
}

/// 释放字符串内存
#[no_mangle]
pub extern "C" fn free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        unsafe {
            // This takes ownership of the string and drops it,
            // effectively freeing the memory
            let _ = CString::from_raw(ptr);
        }
    }
}