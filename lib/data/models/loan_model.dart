import 'dart:math' as math;

enum LoanType { taken, given }

enum InterestType { simple, compound }

enum InterestPeriod { daily, monthly, yearly }

enum LoanStatus { active, completed, overdue }

class LoanPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String? notes;

  LoanPayment({
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

  factory LoanPayment.fromJson(Map<String, dynamic> json) => LoanPayment(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date'] as String).toLocal(),
        notes: json['notes'] as String?,
      );
}

class LoanModel {
  final String id;
  final LoanType type;
  final String personName;
  final String? personContact;
  final double principalAmount;
  final double interestRate; // annual percentage
  final InterestType interestType;
  final InterestPeriod interestPeriod;
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final List<LoanPayment> payments;
  final LoanStatus status;
  final String? notes;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanModel({
    required this.id,
    required this.type,
    required this.personName,
    this.personContact,
    required this.principalAmount,
    required this.interestRate,
    required this.interestType,
    required this.interestPeriod,
    required this.startDate,
    this.expectedEndDate,
    this.payments = const [],
    this.status = LoanStatus.active,
    this.notes,
    this.isSynced = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Total amount paid so far
  double get totalPaid =>
      payments.fold(0.0, (sum, p) => sum + p.amount);

  /// Remaining principal after payments applied to principal
  double get remainingPrincipal {
    final totalInterestAccrued = currentInterest;
    final tp = totalPaid;
    // Payments first cover interest, then principal
    if (tp <= totalInterestAccrued) {
      return principalAmount;
    }
    final principalPaid = tp - totalInterestAccrued;
    final remaining = principalAmount - principalPaid;
    return remaining < 0 ? 0.0 : remaining;
  }

  /// Current interest accrued from start date to now
  double get currentInterest {
    final now = DateTime.now();
    final days = now.difference(startDate).inDays;
    if (days <= 0) return 0.0;

    switch (interestType) {
      case InterestType.simple:
        return _simpleInterest(principalAmount, interestRate, days);
      case InterestType.compound:
        return _compoundInterest(
            principalAmount, interestRate, days, interestPeriod);
    }
  }

  /// Total amount due right now (principal + interest - payments)
  double get totalDueNow {
    final total = principalAmount + currentInterest - totalPaid;
    return total < 0 ? 0.0 : total;
  }

  /// For loans given: total money you'll receive (principal + interest)
  double get expectedTotalReturn {
    if (expectedEndDate == null) return principalAmount + currentInterest;
    final days = expectedEndDate!.difference(startDate).inDays;
    if (days <= 0) return principalAmount;
    switch (interestType) {
      case InterestType.simple:
        return principalAmount +
            _simpleInterest(principalAmount, interestRate, days);
      case InterestType.compound:
        return principalAmount +
            _compoundInterest(
                principalAmount, interestRate, days, interestPeriod);
    }
  }

  static double _simpleInterest(
      double principal, double annualRate, int days) {
    if (principal <= 0 || annualRate <= 0 || days <= 0) return 0.0;
    final rate = annualRate / 100.0;
    final timeYears = days / 365.0;
    final result = principal * rate * timeYears;
    if (result.isNaN || result.isInfinite) return 0.0;
    return double.parse(result.toStringAsFixed(2));
  }

  static double _compoundInterest(
      double principal, double annualRate, int days, InterestPeriod period) {
    final rate = annualRate / 100.0;
    if (rate <= 0) return 0.0;
    int n;
    switch (period) {
      case InterestPeriod.daily:
        n = 365;
        break;
      case InterestPeriod.monthly:
        n = 12;
        break;
      case InterestPeriod.yearly:
        n = 1;
        break;
    }
    final timeYears = days / 365.0;
    final exponent = n * timeYears;
    final base = 1 + rate / n;
    final amount = principal * math.pow(base, exponent);
    if (amount.isNaN || amount.isInfinite) return 0.0;
    return double.parse((amount - principal).toStringAsFixed(2));
  }

  LoanModel copyWith({
    String? id,
    LoanType? type,
    String? personName,
    String? personContact,
    double? principalAmount,
    double? interestRate,
    InterestType? interestType,
    InterestPeriod? interestPeriod,
    DateTime? startDate,
    DateTime? expectedEndDate,
    List<LoanPayment>? payments,
    LoanStatus? status,
    String? notes,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      type: type ?? this.type,
      personName: personName ?? this.personName,
      personContact: personContact ?? this.personContact,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      interestType: interestType ?? this.interestType,
      interestPeriod: interestPeriod ?? this.interestPeriod,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      payments: payments ?? this.payments,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'personName': personName,
        'personContact': personContact,
        'principalAmount': principalAmount,
        'interestRate': interestRate,
        'interestType': interestType.index,
        'interestPeriod': interestPeriod.index,
        'startDate': startDate.toUtc().toIso8601String(),
        'expectedEndDate': expectedEndDate?.toUtc().toIso8601String(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'status': status.index,
        'notes': notes,
        'isSynced': isSynced,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    final typeIdx = json['type'] as int;
    final iTypeIdx = json['interestType'] as int;
    final iPeriodIdx = json['interestPeriod'] as int;
    final statusIdx = json['status'] as int;
    return LoanModel(
      id: json['id'] as String,
      type: typeIdx >= 0 && typeIdx < LoanType.values.length
          ? LoanType.values[typeIdx]
          : LoanType.taken,
      personName: json['personName'] as String? ?? '',
      personContact: json['personContact'] as String?,
      principalAmount: (json['principalAmount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      interestType: iTypeIdx >= 0 && iTypeIdx < InterestType.values.length
          ? InterestType.values[iTypeIdx]
          : InterestType.simple,
      interestPeriod: iPeriodIdx >= 0 && iPeriodIdx < InterestPeriod.values.length
          ? InterestPeriod.values[iPeriodIdx]
          : InterestPeriod.yearly,
      startDate: DateTime.parse(json['startDate'] as String).toLocal(),
      expectedEndDate: json['expectedEndDate'] != null
          ? DateTime.parse(json['expectedEndDate'] as String).toLocal()
          : null,
      payments: (json['payments'] is List)
              ? (json['payments'] as List)
                  .map((e) {
                    try {
                      return LoanPayment.fromJson(e as Map<String, dynamic>);
                    } catch (_) {
                      return null;
                    }
                  })
                  .whereType<LoanPayment>()
                  .toList()
              : [],
      status: statusIdx >= 0 && statusIdx < LoanStatus.values.length
          ? LoanStatus.values[statusIdx]
          : LoanStatus.active,
      notes: json['notes'] as String?,
      isSynced: json['isSynced'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );
  }
}

