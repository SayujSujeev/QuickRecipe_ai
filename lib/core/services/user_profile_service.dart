import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/person_profile.dart';
import '../utils/nutrition_calculator.dart';

/// Firestore-backed storage for the profile-setup wizard.
///
/// Schema:
///   users/{uid}
///     uid, email, displayName, photoUrl, createdAt, updatedAt
///     profileComplete: bool
///     profile: { name, age, heightCm, weightKg, sex, activityLevel, goal,
///                cuisines: [...], cookingStyle, dailyTargets: {...} }
///   users/{uid}/familyMembers/{memberId}
///     same shape as `profile`, plus createdAt
class UserProfileService {
  UserProfileService._();
  static final UserProfileService instance = UserProfileService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Creates the base user document on first sign-in. Safe to call every
  /// time a user is detected — it's a no-op if the document already exists.
  Future<void> ensureUserDocument(User user) async {
    final ref = _users.doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) return;
    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'profileComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isProfileComplete(String uid) async {
    final snap = await _users.doc(uid).get();
    return snap.data()?['profileComplete'] == true;
  }

  /// The signed-in user's stored daily nutrition targets, computed during
  /// the profile-setup wizard. Null if the profile hasn't been completed.
  Future<DailyTargets?> fetchDailyTargets(String uid) async {
    final snap = await _users.doc(uid).get();
    final targets = snap.data()?['profile']?['dailyTargets'];
    if (targets == null) return null;
    return DailyTargets.fromMap(Map<String, dynamic>.from(targets as Map));
  }

  Map<String, dynamic> _profileToMap(PersonProfile p) {
    final targets = computeDailyTargets(p);
    return {
      'name': p.name.trim(),
      'age': p.age,
      'heightCm': p.heightCm,
      'weightKg': p.weightKg,
      'sex': p.sex,
      'activityLevel': p.activityLevel,
      'goal': p.goal,
      'cuisines': p.cuisines.toList(),
      'cookingStyle': p.cookingStyle,
      'dailyTargets': {
        'kcal': targets.kcal,
        'proteinG': targets.proteinG,
        'carbsG': targets.carbsG,
        'fatsG': targets.fatsG,
        'bmi': targets.bmi,
        'bmiCategory': targets.bmiCategory,
      },
    };
  }

  /// Persists the wizard's answers and marks the profile complete so
  /// [isProfileComplete] gates the user straight into the app from now on.
  Future<void> completeProfileSetup({
    required String uid,
    required PersonProfile profile,
    required List<PersonProfile> familyMembers,
  }) async {
    final userRef = _users.doc(uid);
    final familyRef = userRef.collection('familyMembers');

    // Family members are stored as their own docs (not one array field) so
    // each can later be read, edited, or deleted independently.
    final existingFamily = await familyRef.get();

    final batch = _db.batch();
    batch.set(userRef, {
      if (profile.name.trim().isNotEmpty) 'displayName': profile.name.trim(),
      'profile': _profileToMap(profile),
      'profileComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    for (final doc in existingFamily.docs) {
      batch.delete(doc.reference);
    }
    for (final member in familyMembers) {
      batch.set(familyRef.doc(), {
        ..._profileToMap(member),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
