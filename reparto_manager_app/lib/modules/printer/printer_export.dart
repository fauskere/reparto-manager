export 'platform_printer/printer_stub.dart'
  if (dart.library.html) 'platform_printer/printer_web.dart'
  if (dart.library.io) 'platform_printer/printer_mobile.dart';
