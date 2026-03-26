import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

class RustBridge {
  static late DynamicLibrary _dylib;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _createFile;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _readFile;
  static late Pointer<NativeFunction<Pointer Function(Pointer, Pointer)>> _writeFile;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _getFileInfo;
  static late Pointer<NativeFunction<Pointer Function(Pointer)>> _deleteFile;
  static late Pointer<NativeFunction<Void Function(Pointer)>> _freeString;

  static void initialize() {
    String libraryPath = '';

    if (Platform.isWindows) {
      libraryPath = 'fat.dll'; // DLL在运行目录中
    } else if (Platform.isLinux) {
      libraryPath = 'libfat.so';
    } else if (Platform.isMacOS) {
      libraryPath = 'libfat.dylib';
    }

    _dylib = DynamicLibrary.open(libraryPath);

    _createFile = _dylib.lookup('create_file');
    _readFile = _dylib.lookup('read_file');
    _writeFile = _dylib.lookup('write_file');
    _getFileInfo = _dylib.lookup('get_file_info');
    _deleteFile = _dylib.lookup('delete_file');
    _freeString = _dylib.lookup('free_string');
  }

  static String? createFile(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _createFile.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      malloc.free(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? readFile(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _readFile.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      malloc.free(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? writeFile(String path, String content) {
    final pathPtr = path.toNativeUtf8();
    final contentPtr = content.toNativeUtf8();
    try {
      final resultPtr = _writeFile.asFunction<Pointer Function(Pointer, Pointer)>()(pathPtr, contentPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      malloc.free(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
      malloc.free(contentPtr);
    }
  }

  static String? getFileInfo(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _getFileInfo.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      malloc.free(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }

  static String? deleteFile(String path) {
    final pathPtr = path.toNativeUtf8();
    try {
      final resultPtr = _deleteFile.asFunction<Pointer Function(Pointer)>()(pathPtr);
      final result = resultPtr.cast<Utf8>().toDartString();
      malloc.free(resultPtr);
      return result;
    } finally {
      malloc.free(pathPtr);
    }
  }
}