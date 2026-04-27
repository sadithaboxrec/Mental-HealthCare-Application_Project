import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Existing AppUser model — import from wherever it lives
// We'll use a simple Map for now and let the screens adapt

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserDocProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();
  return doc.data();
});
