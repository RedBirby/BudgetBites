enum UserRole { guest, member, admin }

class UserSession {
  const UserSession({required this.username, required this.role});
  final String username;
  final UserRole role;
  bool get isGuest => role == UserRole.guest;
}
