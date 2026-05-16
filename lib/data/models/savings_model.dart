class SavingsContribution {
  final String id;
  final double amount;
  final DateTime date;
  final String? notes;

  SavingsContribution({
    required this.id,
    required this.amount,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toUtc().toIso8601String(),
        'notes': notes,
      };

  factory SavingsContribution.fromJson(Map<String, dynamic> json) =>
      SavingsContribution(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String).toLocal(),
        notes: json['notes'] as String?,
      );
}

class SavingsGoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final DateTime deadline;
  final List<SavingsContribution> contributions;
  final String iconName;
  final int colorValue;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  SavingsGoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.deadline,
    this.contributions = const [],
    this.iconName = 'savings',
    this.colorValue = 0xFF4CAF50,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get totalSaved =>
      contributions.fold(0.0, (sum, c) => sum + c.amount);

  double get progressPercent =>
      targetAmount > 0 ? (totalSaved / targetAmount).clamp(0.0, 1.0) : 0.0;

  double get remainingAmount => (targetAmount - totalSaved).clamp(0, double.infinity);

  int get daysRemaining {
    final diff = deadline.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get requiredPerDay {
    if (daysRemaining <= 0) return remainingAmount;
    return double.parse((remainingAmount / daysRemaining).toStringAsFixed(2));
  }

  double get requiredPerMonth {
    final months = daysRemaining / 30.0;
    if (months <= 0) return remainingAmount;
    return double.parse((remainingAmount / months).toStringAsFixed(2));
  }

  SavingsGoalModel copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? deadline,
    List<SavingsContribution>? contributions,
    String? iconName,
    int? colorValue,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SavingsGoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      deadline: deadline ?? this.deadline,
      contributions: contributions ?? this.contributions,
      iconName: iconName ?? this.iconName,
      colorValue: colorValue ?? this.colorValue,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'deadline': deadline.toUtc().toIso8601String(),
        'contributions': contributions.map((c) => c.toJson()).toList(),
        'iconName': iconName,
        'colorValue': colorValue,
        'isSynced': isSynced,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) =>
      SavingsGoalModel(
        id: json['id'] as String,
        name: json['name'] as String,
        targetAmount: (json['targetAmount'] as num).toDouble(),
        deadline: DateTime.parse(json['deadline'] as String).toLocal(),
        contributions: (json['contributions'] as List?)
                ?.map((e) =>
                    SavingsContribution.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        iconName: json['iconName'] as String? ?? 'savings',
        colorValue: json['colorValue'] as int? ?? 0xFF4CAF50,
        isSynced: json['isSynced'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      );
}

