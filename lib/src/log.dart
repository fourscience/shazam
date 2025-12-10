import 'package:logger/logger.dart';
import 'package:shazam/src/config.dart';

Logger _logger = _buildLogger(Level.info);
Level _currentLevel = Level.info;

void configureLogging(LogLevel level) {
  final mapped = _toLoggerLevel(level);
  if (mapped == _currentLevel) return;
  _currentLevel = mapped;
  _logger = _buildLogger(mapped);
}

void logInfo(String message) => _logger.log(Level.info, message);
void logWarn(String message) => _logger.log(Level.warning, message);
void logError(String message) => _logger.log(Level.error, message);

Logger _buildLogger(Level level) => Logger(
      level: level,
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 80,
        printEmojis: false,
        colors: false,
      ),
    );

Level _toLoggerLevel(LogLevel level) {
  switch (level) {
    case LogLevel.verbose:
      return Level.trace;
    case LogLevel.info:
      return Level.info;
    case LogLevel.warning:
      return Level.warning;
    case LogLevel.error:
      return Level.error;
    case LogLevel.none:
      return Level.off;
  }
}
