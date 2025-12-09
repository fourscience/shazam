import 'dart:io';

void logInfo(String message) => stdout.writeln('[INFO] $message');
void logWarn(String message) => stdout.writeln('[WARN] $message');
void logError(String message) => stderr.writeln('[ERROR] $message');
