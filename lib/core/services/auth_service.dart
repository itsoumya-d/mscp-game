import 'dart:async';

class LocalUser {
  final String? uid;
  final String? email;
  final String? displayName;

  LocalUser({this.uid, this.email, this.displayName});
}

class LocalUserCredential {
  final LocalUser? user;
  LocalUserCredential({this.user});
}

class AuthService {
  AuthService._();
  
  static AuthService? _instance;
  
  static AuthService getInstance() {
    _instance ??= AuthService._();
    return _instance!;
  }
  
  @Deprecated('Use getInstance() instead')
  static AuthService get instance => getInstance();

  Stream<LocalUser?> get authStateChanges => Stream.value(null); // Stub for local mode
  LocalUser? get currentUser => null; // Stub for local mode

  Future<void> signOut() async {
    // Stub for local mode
  }

  Future<LocalUserCredential> signInWithGoogle() async {
    // Stub for local mode
    throw Exception('Auth not configured for local mode');
  }

  Future<LocalUserCredential> signInWithFacebook() async {
    // Stub for local mode
    throw Exception('Auth not configured for local mode');
  }

  Future<LocalUserCredential> signInWithApple() async {
    // Stub for local mode
    throw Exception('Auth not configured for local mode');
  }
}
