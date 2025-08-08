class Agent {
  final int? id;
  final String email;
  final String passwordHash;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;
  final String? faceImagePath;
  final String? biometricId;
  final String? otpCode;

  Agent({
    this.id,
    required this.email,
    required this.passwordHash,
    this.firstName,
    this.lastName,
    this.profilePicture,
    this.faceImagePath,
    this.biometricId,
    this.otpCode,
  });

  factory Agent.fromMap(Map<String, dynamic> map) => Agent(
        id: map['id'],
        email: map['email'],
        passwordHash: map['passwordHash'],
        firstName: map['firstName'],
        lastName: map['lastName'],
        profilePicture: map['profilePicture'],
        faceImagePath: map['faceImagePath'],
        biometricId: map['biometricId'],
        otpCode: map['otpCode'],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'passwordHash': passwordHash,
        'firstName': firstName,
        'lastName': lastName,
        'profilePicture': profilePicture,
        'faceImagePath': faceImagePath,
        'biometricId': biometricId,
        'otpCode': otpCode,
      };
}