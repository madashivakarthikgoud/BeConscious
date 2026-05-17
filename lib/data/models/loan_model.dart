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
    // I = P * R * T (T in years)
    final rate = annualRate / 100.0;
    final timeYears = days / 365.0;
    return double.parse((principal * rate * timeYears).toStringAsFixed(2));
  }

  static double _compoundInterest(
      double principal, double annualRate, int days, InterestPeriod period) {
    // A = P(1 + r/n)^(nt) - P
    // Using dart:math pow for fractional exponents (precise)
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
    // Use fractional exponent for accuracy (not rounding periods)
    final exponent = n * timeYears;
    final base = 1 + rate / n;
    // dart:math pow handles fractional exponents correctly
    final amount = principal * _precisionPow(base, exponent);
    return double.parse((amount - principal).toStringAsFixed(2));
  }

  /// Precise power function supporting fractional exponents
  /// Uses repeated multiplication for integer parts and exp/log for fractional
  static double _precisionPow(double base, double exponent) {
    if (exponent <= 0) return 1.0;
    if (base <= 0) return 0.0;
    // For large integer exponents, use loop (avoids floating point drift)
    final intPart = exponent.truncate();
    final fracPart = exponent - intPart;
    double result = 1.0;
    for (int i = 0; i < intPart; i++) {
      result *= base;
    }
    if (fracPart > 0.0001) {
      // base^frac = e^(frac * ln(base))
      result *= _exp(fracPart * _ln(base));
    }
    return result;
  }

  static double _ln(double x) {
    // Natural log using Taylor series approximation is slow;
    // use the identity: ln(x) via iterative method
    // For production, we use a well-known fast converging formula
    if (x <= 0) return 0;
    if (x == 1) return 0;
    // Use change-of-base with known values for efficiency
    // ln(x) = 2 * atanh((x-1)/(x+1)) for x > 0
    final z = (x - 1) / (x + 1);
    double sum = 0;
    double term = z;
    for (int i = 1; i <= 50; i += 2) {
      sum += term / i;
      term *= z * z;
    }
    return 2 * sum;
  }

  static double _exp(double x) {
    // e^x using Taylor series
    double sum = 1.0;
    double term = 1.0;
    for (int i = 1; i <= 30; i++) {
      term *= x / i;
      sum += term;
      if (term.abs() < 1e-15) break;
    }
    return sum;
  }

  static double _pow(double base, int exponent) {
    if (exponent <= 0) return 1.0;
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
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

  factory LoanModel.fromJson(Map<String, dynamic> json) => LoanModel(
        id: json['id'] as String,
        type: LoanType.values[json['type'] as int],
        personName: json['personName'] as String,
        personContact: json['personContact'] as String?,
        principalAmount: (json['principalAmount'] as num).toDouble(),
        interestRate: (json['interestRate'] as num).toDouble(),
        interestType: InterestType.values[json['interestType'] as int],
        interestPeriod: InterestPeriod.values[json['interestPeriod'] as int],
        startDate: DateTime.parse(json['startDate'] as String).toLocal(),
        expectedEndDate: json['expectedEndDate'] != null
            ? DateTime.parse(json['expectedEndDate'] as String).toLocal()
            : null,
        payments: (json['payments'] as List?)
                ?.map((e) => LoanPayment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        status: LoanStatus.values[json['status'] as int],
        notes: json['notes'] as String?,
        isSynced: json['isSynced'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      );
}

