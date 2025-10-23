import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simulação de autenticação para desenvolvimento
class AuthService {
  static final _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool _isAuthenticated = false;
  String? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  String? get currentUser => _currentUser;

  Future<AuthResult> signIn(String email, String password) async {
    // Simular delay de rede
    await Future.delayed(const Duration(seconds: 1));

    // Validação simples para desenvolvimento
    if (email.isNotEmpty && password.length >= 6) {
      _isAuthenticated = true;
      _currentUser = email;
      return AuthResult(success: true, message: 'Login realizado com sucesso!');
    } else {
      return AuthResult(success: false, message: 'Email ou senha inválidos');
    }
  }

  Future<AuthResult> signUp(String name, String email, String password) async {
    // Simular delay de rede
    await Future.delayed(const Duration(seconds: 1));

    // Validação simples para desenvolvimento
    if (name.isNotEmpty && email.isNotEmpty && password.length >= 6) {
      _isAuthenticated = true;
      _currentUser = email;
      return AuthResult(success: true, message: 'Conta criada com sucesso!');
    } else {
      return AuthResult(success: false, message: 'Dados inválidos');
    }
  }

  Future<void> signOut() async {
    _isAuthenticated = false;
    _currentUser = null;
  }
}

class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}

// Provider para gerenciar estado de autenticação
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  return AuthStateNotifier(ref.read(authServiceProvider));
});

class AuthState {
  final bool isAuthenticated;
  final String? currentUser;
  final bool isLoading;

  AuthState({
    required this.isAuthenticated,
    this.currentUser,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? currentUser,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthStateNotifier(this._authService)
    : super(AuthState(isAuthenticated: false));

  Future<AuthResult> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);

    final result = await _authService.signIn(email, password);

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: result.success,
      currentUser: result.success ? email : null,
    );

    return result;
  }

  Future<AuthResult> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);

    final result = await _authService.signUp(name, email, password);

    state = state.copyWith(
      isLoading: false,
      isAuthenticated: result.success,
      currentUser: result.success ? email : null,
    );

    return result;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState(isAuthenticated: false);
  }
}
