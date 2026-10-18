class User {
  final int? id;
  final String nama;
  final String email;
  final String passwordHash;
  final String salt;

  User({
    this.id,
    required this.nama,
    required this.email,
    required this.passwordHash,
    required this.salt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama': nama,
      'email': email.toLowerCase().trim(),
      'password_hash': passwordHash,
      'salt': salt,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      nama: map['nama'] as String,
      email: (map['email'] as String).toLowerCase(),
      passwordHash: map['password_hash'] as String,
      salt: map['salt'] as String,
    );
  }

  User copyWith({
    int? id,
    String? nama,
    String? email,
    String? passwordHash,
    String? salt,
  }) {
    return User(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
    );
  }
}
