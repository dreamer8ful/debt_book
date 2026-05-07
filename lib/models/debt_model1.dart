import 'package:flutter/material.dart';

class DebtModel {
  final int? id;
  final String name;
  final String? phone; // Made nullable since phone might be optional
  final String type; // 'lend' au 'borrow'
  final double amount;
  final double paidAmount;
  final String dateBorrowed;
  final String? dueDate;
  final String? description;

  DebtModel({
    this.id,
    required this.name,
    this.phone, // Now optional
    required this.type,
    required this.amount,
    this.paidAmount = 0,
    required this.dateBorrowed,
    this.dueDate,
    this.description,
  });

  // Helper getters
  double get remainingAmount => amount - paidAmount;
  
  bool get isFullyPaid => remainingAmount <= 0;
  
  bool get isLend => type == 'lend';
  
  bool get isBorrow => type == 'borrow';
  
  String get displayType => isLend ? 'Lent to' : 'Borrowed from';
  
  String get statusText => isFullyPaid ? 'Fully Paid' : 'Pending';
  
  Color get statusColor => isFullyPaid ? Colors.green : Colors.orange;
  
  double get paidPercentage {
    if (amount <= 0) return 0;
    return (paidAmount / amount) * 100;
  }

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      type: map['type'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      dateBorrowed: map['dateBorrowed'] as String,
      dueDate: map['dueDate'] as String?,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'type': type,
      'amount': amount,
      'paidAmount': paidAmount,
      'dateBorrowed': dateBorrowed,
      'dueDate': dueDate,
      'description': description,
    };
  }
  
  // Create a copy of this debt with updated fields
  DebtModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? type,
    double? amount,
    double? paidAmount,
    String? dateBorrowed,
    String? dueDate,
    String? description,
  }) {
    return DebtModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      dateBorrowed: dateBorrowed ?? this.dateBorrowed,
      dueDate: dueDate ?? this.dueDate,
      description: description ?? this.description,
    );
  }
  
  @override
  String toString() {
    return 'DebtModel(id: $id, name: $name, type: $type, amount: $amount, paid: $paidAmount, remaining: $remainingAmount)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DebtModel &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.amount == amount;
  }
  
  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ type.hashCode;
}