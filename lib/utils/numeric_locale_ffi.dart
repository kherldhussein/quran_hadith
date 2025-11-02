import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart' as pkgffi;

import '../services/error_service.dart';

typedef _NativeSetLocale = ffi.Pointer<ffi.Int8> Function(
    ffi.Int32, ffi.Pointer<ffi.Int8>);
typedef _DartSetLocale = ffi.Pointer<ffi.Int8> Function(
    int, ffi.Pointer<ffi.Int8>);

Future<void> ensureNumericLocale() async {
  if (Platform.isWindows) {
    return;
  }

  try {
    final dylib = ffi.DynamicLibrary.process();
    final setlocale =
        dylib.lookupFunction<_NativeSetLocale, _DartSetLocale>('setlocale');
    const int lcNumeric = 4; // common value on POSIX systems
    final ptr = 'C'.toNativeUtf8();
    setlocale(lcNumeric, ptr.cast<ffi.Int8>());
    pkgffi.malloc.free(ptr);
  } catch (e, s) {
    errorService.reportError(
      'Warning: failed to setlocale(LC_NUMERIC, "C"): $e',
      s,
    );
  }
}
