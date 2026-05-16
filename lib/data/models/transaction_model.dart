
enum TransactionType { income, expense }

enum PaymentMode { cash, upi, creditCard, debitCard, bankTransfer, other }

class TransactionModel {
  final String id;
  final double amount;
  final TransactionType type;
  final DateTime dateTime;
  final String description;
  final String? notes;
  final String moneySourcePerson; // whose money: "Self", "Father", "Mother", custom
  final String beneficiaryPerson; // for whom: "Self", "Family", custom
  final List<String> tags;
  final PaymentMode paymentMode;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.dateTime,
    required this.description,
    this.notes,
    required this.moneySourcePerson,
    required this.beneficiaryPerson,
    required this.tags,
    required this.paymentMode,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  TransactionModel copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    DateTime? dateTime,
    String? description,
    String? notes,
    String? moneySourcePerson,
    String? beneficiaryPerson,
    List<String>? tags,
    PaymentMode? paymentMode,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      moneySourcePerson: moneySourcePerson ?? this.moneySourcePerson,
      beneficiaryPerson: beneficiaryPerson ?? this.beneficiaryPerson,
      tags: tags ?? this.tags,
      paymentMode: paymentMode ?? this.paymentMode,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.index,
        'dateTime': dateTime.toUtc().toIso8601String(),
        'description': description,
        'notes': notes,
        'moneySourcePerson': moneySourcePerson,
        'beneficiaryPerson': beneficiaryPerson,
        'tags': tags,
        'paymentMode': paymentMode.index,
        'isSynced': isSynced,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values[json['type'] as int],
      dateTime: DateTime.parse(json['dateTime'] as String).toLocal(),
      description: json['description'] as String,
      notes: json['notes'] as String?,
      moneySourcePerson: json['moneySourcePerson'] as String,
      beneficiaryPerson: json['beneficiaryPerson'] as String,
      tags: List<String>.from(json['tags'] as List),
      paymentMode: PaymentMode.values[json['paymentMode'] as int],
      isSynced: json['isSynced'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }
}

