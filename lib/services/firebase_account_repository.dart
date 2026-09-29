import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/dietary_preferences.dart';
import 'local_storage_service.dart';

final firebaseAccountRepositoryProvider = Provider<FirebaseAccountRepository>(
  (ref) => FirebaseAccountRepository(),
);

/// Persists the same account-shaped snapshot used by local storage, allowing
/// the controller and screens to stay independent from Firestore details.
class FirebaseAccountRepository {
  bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  Future<StoredAccountState> read(String uid) async {
    if (!isAvailable) return _emptyState;
    final snapshot = await _document(uid).get();
    final data = snapshot.data();
    return data == null ? _emptyState : StoredAccountState.fromJson(data);
  }

  Future<void> write({
    required String uid,
    required StoredAccountState account,
  }) async {
    if (!isAvailable) return;
    await _document(uid).set({
      ...account.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static const _emptyState = StoredAccountState(
    preferences: DietaryPreferences(),
    savedRecipeIds: {},
    budgetItems: [],
    weeklyBudget: 100,
  );
}
