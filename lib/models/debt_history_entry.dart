class DebtHistoryEntry {
  final int? id;
  final int debtId;
  final String action;
  final double? amount;
  final double? balanceAfter;
  final String? note;
  final String createdAt;

  const DebtHistoryEntry({
    this.id,
    required this.debtId,
    required this.action,
    this.amount,
    this.balanceAfter,
    this.note,
    required this.createdAt,
  });

  factory DebtHistoryEntry.fromMap(Map<String, dynamic> map) {
    return DebtHistoryEntry(
      id: map['id'] as int?,
      debtId: map['debtId'] as int,
      action: map['action'] as String,
      amount: (map['amount'] as num?)?.toDouble(),
      balanceAfter: (map['balanceAfter'] as num?)?.toDouble(),
      note: map['note'] as String?,
      createdAt: map['createdAt'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'action': action,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'note': note,
      'createdAt': createdAt,
    };
  }
}