import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GlobalErrorHandler {
  static GlobalKey<NavigatorState>? _navigatorKey;
  static bool _isDialogOpen = false;

  static void initialize({required GlobalKey<NavigatorState> navigatorKey}) {
    _navigatorKey = navigatorKey;

    // Route Flutter errors into the current zone so our zone handler picks them up
    FlutterError.onError = (FlutterErrorDetails details) {
      Zone.current.handleUncaughtError(details.exception, details.stack ?? StackTrace.current);
    };

    // Catch errors that escape to the platform dispatcher (async, isolates)
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      _showErrorDialog(error, stack);
      return true; // prevent default error reporting
    };

    // Customize ErrorWidget so release-mode gray screen also triggers a dialog
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Fire-and-forget dialog; still render a minimal widget to avoid build crashes
      _showErrorDialog(details.exception, details.stack ?? StackTrace.current);
      return Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: const Text(
          'Something went wrong',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    };
  }

  static void recordError(Object error, StackTrace stack) {
    _showErrorDialog(error, stack);
  }

  static Future<void> onException(Object error, [StackTrace? stack]) async {
    _showErrorDialog(error, stack ?? StackTrace.current);
  }

  static void _showErrorDialog(Object error, StackTrace stack) {
    try {
      if (_navigatorKey?.currentState == null) {
        // Navigator not ready; just log
        debugPrint('GlobalErrorHandler: navigator not ready for dialog');
        debugPrint('ERROR: $error');
        debugPrint('STACK: $stack');
        return;
      }

      if (_isDialogOpen) {
        // Avoid flooding with dialogs
        return;
      }
      _isDialogOpen = true;

      final BuildContext? context = _navigatorKey!.currentState!.overlay?.context;
      if (context == null) {
        debugPrint('GlobalErrorHandler: no overlay context available');
        debugPrint('ERROR: $error');
        debugPrint('STACK: $stack');
        _isDialogOpen = false;
        return;
      }

      final String errorText = _formatErrorForDisplay(error, stack);

      // Schedule after current frame to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Unexpected Error'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320, minWidth: 280),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      errorText,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: errorText));
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Error copied to clipboard')),
                    );
                  },
                  child: const Text('Copy'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
        _isDialogOpen = false;
      });
    } catch (dialogError, dialogStack) {
      // As a last resort, log to console
      debugPrint('GlobalErrorHandler failed to present dialog: $dialogError');
      debugPrint('Dialog STACK: $dialogStack');
      debugPrint('Original ERROR: $error');
      debugPrint('Original STACK: $stack');
      _isDialogOpen = false;
    }
  }

  static String _formatErrorForDisplay(Object error, StackTrace stack) {
    final String timestamp = DateTime.now().toIso8601String();
    final buffer = StringBuffer()
      ..writeln('Time: $timestamp')
      ..writeln('Error: $error')
      ..writeln('')
      ..writeln('Stack trace:')
      ..writeln(stack.toString());
    return buffer.toString();
  }
}