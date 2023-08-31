class TokensEntity {
  final String accessToken;
  final String refreshToken;
  final int expirationDays;

  const TokensEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.expirationDays,
  });
}
