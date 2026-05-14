import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../models/file_item.dart';
import '../../rust_bridge.dart';
import '../constants/app_colors.dart';

class HomeController extends GetxController with TrayListener, WindowListener {
  final filecatPath = ''.obs;
  final directoryContents = <FileItem>[].obs;
  final expandedFolders = <String, bool>{}.obs;
  final folderContents = <String, List<FileItem>>{}.obs;
  final isLoading = false.obs;
  final autostartEnabled = false.obs;
  final serverRunning = false.obs;

  @override
  void onInit() {
    super.onInit();
    windowManager.addListener(this);
    _setPreventClose();
    _initTray();
    _loadFilecatPath();
    _loadAutostartPreference();
  }

  @override
  void onClose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.onClose();
  }

  void _setPreventClose() async {
    await windowManager.setPreventClose(true);
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
      updateTrayMenu(forceVisible: false);
    }
  }

  @override
  void onWindowHide() {
    updateTrayMenu(forceVisible: false);
  }

  @override
  void onWindowShow() {
    updateTrayMenu(forceVisible: true);
  }

  Future<void> updateTrayMenu({bool? forceVisible}) async {
    bool isVisible = forceVisible ?? await windowManager.isVisible();
    final menu = Menu(
      items: [
        MenuItem(
          key: 'toggle_window',
          label: isVisible ? '隐藏窗口' : '显示窗口',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'support',
          label: '支持作者',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'about',
          label: '关于',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: '退出',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  void _initTray() async {
    trayManager.addListener(this);
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/images/app_icon.ico' : 'assets/images/app_icon.ico',
    );
    await trayManager.setToolTip('文件猫');
    updateTrayMenu(forceVisible: true);
  }

  @override
  void onTrayIconMouseDown() async {
    bool isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
      updateTrayMenu(forceVisible: false);
    } else {
      await windowManager.show();
      await windowManager.focus();
      updateTrayMenu(forceVisible: true);
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    updateTrayMenu().then((_) {
      trayManager.popUpContextMenu();
    });
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'toggle_window') {
      bool isVisible = await windowManager.isVisible();
      if (isVisible) {
        await windowManager.hide();
        updateTrayMenu(forceVisible: false);
      } else {
        await windowManager.show();
        await windowManager.focus();
        updateTrayMenu(forceVisible: true);
      }
    } else if (menuItem.key == 'support') {
      showSupportDialog();
    } else if (menuItem.key == 'about') {
      showAboutDialog();
    } else if (menuItem.key == 'exit') {
      exit(0);
    }
  }

  void showAboutDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Image.asset(
                    'assets/images/close.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '文件猫',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '一个 Flutter + Rust 混合开发的\n文件管理应用',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '支持系统托盘 · 文件浏览 · 局域网共享',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSupportDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Image.asset(
                    'assets/images/close.png',
                    width: 28,
                    height: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/wechat_pay.jpg',
                  width: 240,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '支持一下作者吧~~~',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '您的支持是我持续更新的最大动力',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadAutostartPreference() async {
    final prefs = await SharedPreferences.getInstance();
    autostartEnabled.value = prefs.getBool('autostart_enabled') ?? false;
    serverRunning.value = RustBridge.isServerRunning();
  }

  void _loadFilecatPath() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString('filecat_path');
    
    if (savedPath != null && savedPath.isNotEmpty) {
      filecatPath.value = savedPath;
      _loadDirectoryContents(savedPath);
      RustBridge.startStaticServer(savedPath);
    } else {
      final path = RustBridge.getFilecatPath();
      if (path != null) {
        try {
          final pathStr = path.contains('"data":"') 
              ? path.split('"data":"')[1].split('"')[0]
              : path;
          filecatPath.value = pathStr;
          _loadDirectoryContents(pathStr);
          RustBridge.startStaticServer(pathStr);
        } catch (e) {
          filecatPath.value = path;
          _loadDirectoryContents(path);
          RustBridge.startStaticServer(path);
        }
      }
    }
  }

  void _loadDirectoryContents(String path) {
    isLoading.value = true;
    final result = RustBridge.listDirectory(path);
    if (result != null) {
      try {
        final List<dynamic> jsonList = _extractJsonArray(result);
        directoryContents.value = jsonList.map((item) => FileItem.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        directoryContents.clear();
      }
    }
    isLoading.value = false;
  }

  List<dynamic> _extractJsonArray(String response) {
    try {
      final startIndex = response.indexOf('[');
      final endIndex = response.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1) {
        final jsonArray = response.substring(startIndex, endIndex + 1);
        return jsonDecode(jsonArray) as List<dynamic>;
      }
    } catch (e) {
      debugPrint('Error extracting JSON array: $e');
    }
    return [];
  }

  void toggleFolder(String path) {
    if (expandedFolders[path] == true) {
      expandedFolders[path] = false;
    } else {
      expandedFolders[path] = true;
      _loadFolderContents(path);
    }
  }

  void refreshContents() {
    if (filecatPath.value.isNotEmpty) {
      _loadDirectoryContents(filecatPath.value);
      for (var entry in expandedFolders.entries) {
        if (entry.value) {
          _loadFolderContents(entry.key);
        }
      }
      Get.snackbar('提示', '已刷新目录内容', snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _loadFolderContents(String path) {
    final result = RustBridge.listDirectory(path);
    if (result != null) {
      try {
        final List<dynamic> jsonList = _extractJsonArray(result);
        folderContents[path] = jsonList.map((item) => FileItem.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Error loading folder contents: $e');
      }
    }
  }

  void changeFilecatPath(String? selectedDirectory) async {
    if (selectedDirectory != null) {
      filecatPath.value = selectedDirectory;
      directoryContents.clear();
      expandedFolders.clear();
      folderContents.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('filecat_path', selectedDirectory);
      
      _loadDirectoryContents(selectedDirectory);
      RustBridge.updateServerPath(selectedDirectory);
    }
  }

  Future<void> setAutostart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      final result = RustBridge.enableAutostart('文件猫');
      if (result != null) {
        try {
          final json = jsonDecode(result);
          if (json['success'] == true) {
            await prefs.setBool('autostart_enabled', true);
            autostartEnabled.value = true;
          }
        } catch (e) {
          debugPrint('Error enabling autostart: $e');
        }
      }
    } else {
      final result = RustBridge.disableAutostart('文件猫');
      if (result != null) {
        try {
          final json = jsonDecode(result);
          if (json['success'] == true) {
            await prefs.setBool('autostart_enabled', false);
            autostartEnabled.value = false;
          }
        } catch (e) {
          debugPrint('Error disabling autostart: $e');
        }
      }
    }
  }

  void copyFileRelativePath(FileItem item) {
    final filePath = item.path;
    String relativePath = filePath;

    if (filecatPath.value.isNotEmpty && filePath.startsWith(filecatPath.value)) {
      relativePath = filePath.substring(filecatPath.value.length);
      if (relativePath.startsWith('/') || relativePath.startsWith('\\')) {
        relativePath = relativePath.substring(1);
      }
    }

    relativePath = relativePath.replaceAll('\\', '/');

    final ipResult = RustBridge.getLocalIp();
    String ip = '127.0.0.1';
    if (ipResult != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(ipResult);
        if (json['success'] == true) {
          ip = json['data'] as String;
        }
      } catch (e) {
        debugPrint('Error parsing local IP: $e');
      }
    }

    final fullUrl = 'http://$ip:9202/file/$relativePath';
    Clipboard.setData(ClipboardData(text: fullUrl));
    Get.snackbar('已复制', fullUrl, snackPosition: SnackPosition.BOTTOM);
  }
}
