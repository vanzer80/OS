import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';

/// Handler global de erros para a aplicação
class ErrorHandler {
  static final _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final AnalyticsService _analytics = AnalyticsService();

  /// Inicializa o handler de erros
  static void initialize() {
    final handler = ErrorHandler();

    // Captura erros do Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      handler._handleFlutterError(details);
    };

    // Captura erros não tratados em zonas assíncronas
    PlatformDispatcher.instance.onError = (error, stack) {
      handler._handlePlatformError(error, stack);
      return true;
    };
  }

  /// Trata erros do Flutter framework
  void _handleFlutterError(FlutterErrorDetails details) {
    // Log no console para desenvolvimento
    if (kDebugMode) {
      FlutterError.presentError(details);
    }

    // Envia erro para analytics
    _analytics.trackError(
      details.exception.toString(),
      stackTrace: details.stack.toString(),
      context: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
    );
  }

  /// Trata erros da plataforma
  void _handlePlatformError(Object error, StackTrace stack) {
    // Log no console para desenvolvimento
    if (kDebugMode) {
      print('Platform Error: $error');
      print('Stack Trace: $stack');
    }

    // Envia erro para analytics
    _analytics.trackError(
      error.toString(),
      stackTrace: stack.toString(),
      context: {
        'type': 'platform_error',
        'error_type': error.runtimeType.toString(),
      },
    );
  }

  /// Reporta erro manualmente
  static void reportError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    final handler = ErrorHandler();

    if (kDebugMode) {
      print('Manual Error Report: $error');
      if (stackTrace != null) {
        print('Stack Trace: $stackTrace');
      }
      if (context != null) {
        print('Context: $context');
      }
    }

    handler._analytics.trackError(
      error.toString(),
      stackTrace: stackTrace?.toString(),
      context: {
        'manual_report': true,
        'context': context,
        'additional_data': additionalData,
      },
    );
  }

  /// Reporta erro de rede
  static void reportNetworkError(
    String endpoint,
    int? statusCode,
    String error, {
    Map<String, dynamic>? requestData,
  }) {
    final handler = ErrorHandler();

    handler._analytics.trackError(
      'Network Error: $error',
      context: {
        'type': 'network_error',
        'endpoint': endpoint,
        'status_code': statusCode,
        'request_data': requestData,
      },
    );
  }

  /// Reporta erro de autenticação
  static void reportAuthError(String error, {String? method}) {
    final handler = ErrorHandler();

    handler._analytics.trackError(
      'Auth Error: $error',
      context: {'type': 'auth_error', 'method': method},
    );
  }

  /// Reporta erro de validação
  static void reportValidationError(String field, String error) {
    final handler = ErrorHandler();

    handler._analytics.trackError(
      'Validation Error: $error',
      context: {'type': 'validation_error', 'field': field},
    );
  }
}

/// Widget para capturar erros em uma árvore de widgets
class ErrorBoundary extends ConsumerWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace? stackTrace)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return child;
  }
}

/// Widget padrão para exibir erros
class _DefaultErrorWidget extends StatelessWidget {
  final String error;

  const _DefaultErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Ops! Algo deu errado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Nosso time foi notificado sobre este erro.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Recarrega a aplicação
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Tentar Novamente'),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('Detalhes do Erro (Debug)'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      error,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mixin para facilitar o reporte de erros em widgets
mixin ErrorReportingMixin {
  /// Reporta erro com contexto do widget
  void reportError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    ErrorHandler.reportError(
      error,
      stackTrace: stackTrace,
      context: context ?? runtimeType.toString(),
      additionalData: additionalData,
    );
  }

  /// Executa função com tratamento de erro
  Future<T?> safeExecute<T>(
    Future<T> Function() function, {
    String? context,
    T? fallback,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      reportError(
        error,
        stackTrace: stackTrace,
        context: context ?? 'safeExecute',
      );
      return fallback;
    }
  }

  /// Executa função síncrona com tratamento de erro
  T? safeExecuteSync<T>(T Function() function, {String? context, T? fallback}) {
    try {
      return function();
    } catch (error, stackTrace) {
      reportError(
        error,
        stackTrace: stackTrace,
        context: context ?? 'safeExecuteSync',
      );
      return fallback;
    }
  }
}

/// Função utilitária para executar código com tratamento de erro
Future<T?> runSafely<T>(
  Future<T> Function() function, {
  String? context,
  T? fallback,
}) async {
  try {
    return await function();
  } catch (error, stackTrace) {
    ErrorHandler.reportError(
      error,
      stackTrace: stackTrace,
      context: context ?? 'runSafely',
    );
    return fallback;
  }
}
