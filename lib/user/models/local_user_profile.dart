class LocalUserProfile {
  final String displayName;
  final String? email;
  final DateTime? joinedAt;
  final String? avatarBase64;

  const LocalUserProfile({
    this.displayName = '',
    this.email,
    this.joinedAt,
    this.avatarBase64,
  });

  LocalUserProfile copyWith({
    String? displayName,
    String? email,
    bool clearEmail = false,
    DateTime? joinedAt,
    String? avatarBase64,
    bool clearAvatar = false,
  }) {
    return LocalUserProfile(
      displayName: displayName ?? this.displayName,
      email: clearEmail ? null : email ?? this.email,
      joinedAt: joinedAt ?? this.joinedAt,
      avatarBase64: clearAvatar ? null : avatarBase64 ?? this.avatarBase64,
    );
  }

  factory LocalUserProfile.fromMap(Map<String, dynamic> map) {
    return LocalUserProfile(
      displayName: map['displayName']?.toString() ?? '',
      email: map['email']?.toString(),
      joinedAt: DateTime.tryParse(map['joinedAt']?.toString() ?? ''),
      avatarBase64: map['avatarBase64']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'joinedAt': joinedAt?.toIso8601String(),
      'avatarBase64': avatarBase64,
    };
  }
}
