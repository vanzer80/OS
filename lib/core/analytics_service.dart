import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Serviço de Analytics para monitoramento durante período de testes
class AnalyticsService {
  static final _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Configurações
  static const String _analyticsEndpoint = 'https://api.vercel.com/v1/analytics';
  static const bool _enableAnalytics = kReleaseMode; // Apenas em produção

  /// Registra evento de página visitada
  Future<void> trackPageView(String pageName) async {
    if (!_enableAnalytics) return;
    
    try {
      await _sendEvent('page_view', {
        'page_name': pageName,
        'timestamp': DateTime.now().toIso8601String(),
        'user_agent': 'Flutter Web',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao registrar page view: $e');
      }
    }
  }

  /// Registra evento de ação do usuário
  Future<void> trackUserAction(String action, {Map<String, dynamic>? properties}) async {
    if (!_enableAnalytics) return;
    
    try {
      await _sendEvent('user_action', {
        'action': action,
        'properties': properties ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao registrar ação do usuário: $e');
      }
    }
  }

  /// Registra erro da aplicação
  Future<void> trackError(String error, {String? stackTrace, Map<String, dynamic>? context}) async {
    if (!_enableAnalytics) return;
    
    try {
      await _sendEvent('error', {
        'error_message': error,
        'stack_trace': stackTrace,
        'context': context ?? {},
        'timestamp': DateTime.now().toIso8601String(),
        'severity': 'error',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao registrar erro: $e');
      }
    }
  }

  /// Registra métricas de performance
  Future<void> trackPerformance(String metric, double value, {String? unit}) async {
    if (!_enableAnalytics) return;
    
    try {
      await _sendEvent('performance', {
        'metric_name': metric,
        'value': value,
        'unit': unit ?? 'ms',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao registrar métrica de performance: $e');
      }
    }
  }

  /// Registra evento de login
  Future<void> trackLogin(String method) async {
    if (!_enableAnalytics) return;
    
    try {
      await _sendEvent('login', {
        'method': method,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao registrar login: $e');
      }
    }
  }

  /// Registra evento de logout
  Future<void> trackLogout() async {
    if (!_enableAnalytics) return;
    
    try {
      await _sendEvent('logout', {
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao registrar logout: $e');
      }
    }
  }

  /// Registra criação de ordem de serviço
  Future<void> trackOrderCreated(String orderId) async {
    if (!_enableAnalytics) return;
    
    try {
      await _sendEvent('order_created', {
        'order_id': orderId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao registrar criação de ordem: $e');
      }
    }
  }

  /// Registra feedback do usuário
  Future<void> trackFeedback(String type, String message, {int? rating}) async {
    if (!_enableAnalytics) return;
    
    try {
      await _sendEvent('feedback', {
        'type': type,
        'message': message,
        'rating': rating,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao registrar feedback: $e');
      }
    }
  }

  /// Envia evento para o endpoint de analytics
  Future<void> _sendEvent(String eventType, Map<String, dynamic> data) async {
    if (!_enableAnalytics) return;

    try {
      // Para o período de testes, vamos usar um endpoint simples
      // Em produção, você pode integrar com Google Analytics, Mixpanel, etc.
      
      final payload = {
        'event_type': eventType,
        'data': data,
        'app_version': '1.0.3',
        'platform': 'web',
        'environment': kReleaseMode ? 'production' : 'development',
      };

      // Log local para desenvolvimento
      if (kDebugMode) {
        print('Analytics Event: ${jsonEncode(payload)}');
      }

      // Em produção, enviar para serviço de analytics
      if (kReleaseMode) {
        // Implementar integração com serviço de analytics real
        // Exemplo: Google Analytics, Mixpanel, Amplitude, etc.
        
        // Por enquanto, apenas log no console do navegador
        if (kIsWeb) {
          // No Flutter Web, podemos usar window.console.log
          // ou integrar com Google Analytics via JavaScript
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao enviar evento de analytics: $e');
      }
    }
  }
}

/// Provider para o serviço de analytics
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Mixin para facilitar o uso de analytics em widgets
mixin AnalyticsMixin {
  AnalyticsService get analytics => AnalyticsService();

  /// Registra visualização de tela
  void trackScreen(String screenName) {
    analytics.trackPageView(screenName);
  }

  /// Registra ação do usuário
  void trackAction(String action, {Map<String, dynamic>? properties}) {
    analytics.trackUserAction(action, properties: properties);
  }

  /// Registra erro
  void trackError(String error, {String? stackTrace, Map<String, dynamic>? context}) {
    analytics.trackError(error, stackTrace: stackTrace, context: context);
  }
}

/// Classe para métricas de performance
class PerformanceTracker {
  final String _metricName;
  final DateTime _startTime;
  final AnalyticsService _analytics;

  PerformanceTracker(this._metricName) 
    : _startTime = DateTime.now(),
      _analytics = AnalyticsService();

  /// Finaliza a medição e envia a métrica
  void finish() {
    final duration = DateTime.now().difference(_startTime);
    _analytics.trackPerformance(_metricName, duration.inMilliseconds.toDouble());
  }
}

/// Função utilitária para medir performance
PerformanceTracker startPerformanceTracking(String metricName) {
  return PerformanceTracker(metricName);
}