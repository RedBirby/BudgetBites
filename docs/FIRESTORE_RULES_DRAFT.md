# Firestore rules draft

This is a review draft only. It is **not deployed**. Review it in the Firebase
Console with the instructor before replacing the active rules or publishing the
app.

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function ownsUserDocument(userId) {
      return signedIn() && request.auth.uid == userId;
    }

    match /users/{userId} {
      // A user can only read their own account snapshot.
      allow read: if ownsUserDocument(userId);

      // The app writes this account-shaped snapshot from the signed-in client.
      // Restrict fields and budget values so arbitrary data cannot be added.
      allow create, update: if ownsUserDocument(userId)
        && request.resource.data.keys().hasOnly([
          'preferences',
          'savedRecipeIds',
          'budgetItems',
          'weeklyBudget',
          'plannedRecipes',
          'zipCode',
          'updatedAt'
        ])
        && request.resource.data.weeklyBudget is number
        && request.resource.data.weeklyBudget >= 0;

      // Account documents should not be deleted from the client.
      allow delete: if false;
    }

    // No other collections are public by default.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## Review checklist

- Confirm the field names match `StoredAccountState.toJson()` in the app.
- Test sign-in, account creation, preference changes, saved recipes, plan items,
  budget items, and ZIP persistence in the Firebase Rules simulator.
- Confirm a signed-in user cannot read or write another user's `/users/{uid}`
  document.
- Confirm signed-out users and guests cannot access Firestore.
- Decide whether account deletion should be handled by a trusted backend instead
  of a client rule.
- If Firebase Storage is added later, create separate Storage rules; this app
  currently has no Storage upload/download feature.
