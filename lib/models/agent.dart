class Agent {
  final int? id;
  final String email;
  final String passwordHash;

  Agent({this.id, required this.email, required this.passwordHash});

  factory Agent.fromMap(Map<String, dynamic> map) => Agent(
        id: map['id'],
        email: map['email'],
        passwordHash: map['passwordHash'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'passwordHash': passwordHash,
      };
}