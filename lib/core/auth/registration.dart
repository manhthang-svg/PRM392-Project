class RegistrationDraft {
  const RegistrationDraft({
    required this.displayName,
    required this.handle,
    required this.email,
    required this.password,
  });

  final String displayName;
  final String handle;
  final String email;
  final String password;
}

class OtpChallenge {
  const OtpChallenge({
    required this.email,
    required this.expiresIn,
    required this.resendIn,
  });

  factory OtpChallenge.fromApiData(Map<String, dynamic> data) {
    return OtpChallenge(
      email: data['email'] as String,
      expiresIn: (data['expiresIn'] as num).toInt(),
      resendIn: (data['resendIn'] as num).toInt(),
    );
  }

  final String email;
  final int expiresIn;
  final int resendIn;
}
