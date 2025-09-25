import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Serviço de autenticação real com Supabase
class SupabaseAuthService {
  static final _instance = SupabaseAuthService._internal();
  factory SupabaseAuthService() => _instance;
  SupabaseAuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Future<AuthResult> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return AuthResult(success: true, message: 'Login realizado com sucesso!');
      } else {
        return AuthResult(success: false, message: 'Erro no login');
      }
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (error) {
      return AuthResult(success: false, message: 'Erro inesperado: $error');
    }
  }

  Future<AuthResult> signUp(String name, String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );

      if (response.user != null) {
        return AuthResult(
          success: true, 
          message: 'Conta criada com sucesso! Verifique seu email para confirmar.',
        );
      } else {
        return AuthResult(success: false, message: 'Erro ao criar conta');
      }
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (error) {
      return AuthResult(success: false, message: 'Erro inesperado: $error');
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(OAuthProvider.google);
      return AuthResult(success: true, message: 'Login com Google realizado com sucesso!');
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (error) {
      return AuthResult(success: false, message: 'Erro no login com Google: $error');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Stream para escutar mudanças no estado de autenticação
  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((data) {
      return AuthState(
        isAuthenticated: data.session != null,
        currentUser: data.session?.user?.email,
        isLoading: false,
      );
    });
  }
}

class AuthResult {
  final bool success;
  final String message;

  AuthResult({required this.success, required this.message});
}

// Provider para gerenciar estado de autenticação com Supabase
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) => SupabaseAuthService());

final supabaseAuthStateProvider = StateNotifierProvider<SupabaseAuthStateNotifier, AuthState>((ref) {
  return SupabaseAuthStateNotifier(ref.read(supabaseAuthServiceProvider));
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

class SupabaseAuthStateNotifier extends StateNotifier<AuthState> {
  final SupabaseAuthService _authService;

  SupabaseAuthStateNotifier(this._authService) : super(AuthState(isAuthenticated: false)) {
    // Verificar se já está logado
    _checkInitialAuth();
    
    // Escutar mudanças no estado de autenticação
    _authService.authStateChanges.listen((authState) {
      state = authState;
    });
  }

  void _checkInitialAuth() {
    final user = _authService.currentUser;
    if (user != null) {
      state = AuthState(
        isAuthenticated: true,
        currentUser: user.email,
      );
    }
  }

  Future<AuthResult> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authService.signIn(email, password);
    
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: email,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
    
    return result;
  }

  Future<AuthResult> signUp(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authService.signUp(name, email, password);
    
    if (result.success) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        currentUser: email,
      );
    } else {
      state = state.copyWith(isLoading: false);
    }
    
    return result;
  }

  Future<AuthResult> signInWithGoogle() async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authService.signInWithGoogle();
    
    state = state.copyWith(isLoading: false);
    
    return result;
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = AuthState(isAuthenticated: false);
  }
}
