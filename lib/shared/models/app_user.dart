/// Roles planned by the architecture. The mobile app only serves `youth`;
/// the other roles are handled by the API.
enum UserRole { youth, association, institution, company, admin }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    this.nameLatin,
    this.phone,
    this.email,
    this.role = UserRole.youth,
  });

  final String id;
  final String name;

  /// Optional Latin spelling shown when the interface is in French.
  final String? nameLatin;
  final String? phone;
  final String? email;
  final UserRole role;

  String displayName(bool isAr) => (!isAr && nameLatin != null && nameLatin!.isNotEmpty) ? nameLatin! : name;

  String firstName(bool isAr) => displayName(isAr).trim().split(RegExp(r'\s+')).first;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'nameLatin': nameLatin,
    'phone': phone,
    'email': email,
    'role': role.name,
  };

  factory AppUser.fromJson(Map<dynamic, dynamic> json) => AppUser(
    id: json['id'] as String,
    name: json['name'] as String,
    nameLatin: json['nameLatin'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    role: UserRole.values.firstWhere((r) => r.name == json['role'], orElse: () => UserRole.youth),
  );
}
