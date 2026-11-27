import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

abstract class AuthDataSource {
  Future<UserModel?> getActiveSession();
  Future<void> clearActiveSession();
  Future<UserModel?> login({
    required String email,
    required String password,
  });
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  });
  Future<UserModel?> signInWithGoogle();
  Future<void> updateUser(UserModel user);
  Future<UserModel?> getUserById(String id);
  Future<UserModel?> getUserByEmail(String email);
  Stream<User?> authStateChanges();
}

class FirebaseAuthDataSource implements AuthDataSource {
  FirebaseAuthDataSource({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuthOverride = firebaseAuth,
        _firestoreOverride = firestore,
        _googleSignInOverride = googleSignIn;

  final FirebaseAuth? _firebaseAuthOverride;
  final FirebaseFirestore? _firestoreOverride;
  GoogleSignIn? _googleSignInOverride;

  FirebaseAuth get _firebaseAuth =>
      _firebaseAuthOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn =>
      _googleSignInOverride ??= GoogleSignIn();

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  Future<UserModel?> getActiveSession() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return await _fetchOrCreateUserDoc(fbUser);
  }

  @override
  Future<void> clearActiveSession() async {
    await _firebaseAuth.signOut();
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
  }

  @override
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final fbUser = credential.user;
      if (fbUser == null) return null;
      return await _fetchOrCreateUserDoc(fbUser);
    } on FirebaseAuthException {
      return null;
    }
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = fullName.trim();

    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
    final fbUser = credential.user!;
    await fbUser.updateDisplayName(cleanName);

    final newUser = UserModel(
      id: fbUser.uid,
      fullName: cleanName,
      email: cleanEmail,
      selectedConditions: const [],
      primaryGoal: 'Deteksi Bahan Berbahaya & ADI',
      hasCompletedHealthSurvey: false,
      provider: 'email',
      createdAt: DateTime.now(),
    );

    await _usersCollection.doc(fbUser.uid).set(newUser.toJson());
    return newUser;
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final fbUser = userCredential.user;
    if (fbUser == null) return null;

    return await _fetchOrCreateUserDoc(fbUser, provider: 'google');
  }

  Future<UserModel> _fetchOrCreateUserDoc(
    User fbUser, {
    String provider = 'email',
  }) async {
    final doc = await _usersCollection.doc(fbUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromJson({...doc.data()!, 'uid': fbUser.uid});
    }

    final fallbackUser = UserModel(
      id: fbUser.uid,
      fullName: fbUser.displayName?.trim().isNotEmpty == true
          ? fbUser.displayName!.trim()
          : (fbUser.email?.split('@').first ?? 'Pengguna'),
      email: fbUser.email?.toLowerCase() ?? '',
      avatarUrl: fbUser.photoURL ?? '',
      hasCompletedHealthSurvey: false,
      provider: provider,
      createdAt: DateTime.now(),
    );
    await _usersCollection.doc(fbUser.uid).set(fallbackUser.toJson());
    return fallbackUser;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _usersCollection
        .doc(user.id)
        .set(user.toJson(), SetOptions(merge: true));
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    final doc = await _usersCollection.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final query = await _usersCollection
        .where('email', isEqualTo: cleanEmail)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return UserModel.fromJson({...doc.data(), 'uid': doc.id});
  }
}
