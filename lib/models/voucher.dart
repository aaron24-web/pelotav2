class Voucher {
  final String id;
  final String coinPackId;
  final DateTime purchaseDate;
  final int amount;

  Voucher({
    required this.id,
    required this.coinPackId,
    required this.purchaseDate,
    required this.amount,
  });
}
