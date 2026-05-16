import '../../data/models/loan_model.dart';

/// Precision loan calculator utilities
class LoanCalculator {
  /// Calculate simple interest: I = P × R × T
  /// [principal] - loan amount
  /// [annualRate] - annual interest rate in percentage (e.g., 12 for 12%)
  /// [days] - number of days
  static double simpleInterest({
    required double principal,
    required double annualRate,
    required int days,
  }) {
    final rate = annualRate / 100.0;
    final timeYears = days / 365.0;
    return double.parse((principal * rate * timeYears).toStringAsFixed(2));
  }

  /// Calculate compound interest: A = P(1 + r/n)^(nt) - P
  /// [compoundingFrequency] - 365=daily, 12=monthly, 1=yearly
  static double compoundInterest({
    required double principal,
    required double annualRate,
    required int days,
    required int compoundingFrequency,
  }) {
    final rate = annualRate / 100.0;
    final n = compoundingFrequency;
    final timeYears = days / 365.0;
    final periods = (n * timeYears).round();

    double amount = principal;
    final factor = 1 + rate / n;
    for (int i = 0; i < periods; i++) {
      amount *= factor;
    }
    return double.parse((amount - principal).toStringAsFixed(2));
  }

  /// Get full loan status summary
  static Map<String, double> getLoanSummary(LoanModel loan) {
    return {
      'principal': loan.principalAmount,
      'interestAccrued': loan.currentInterest,
      'totalWithInterest': loan.principalAmount + loan.currentInterest,
      'totalPaid': loan.totalPaid,
      'totalDueNow': loan.totalDueNow,
      'remainingPrincipal': loan.remainingPrincipal,
    };
  }

  /// Calculate monthly EMI for a loan
  /// EMI = [P × R × (1+R)^N] / [(1+R)^N – 1]
  static double calculateEMI({
    required double principal,
    required double annualRate,
    required int months,
  }) {
    if (months <= 0) return principal;
    if (annualRate <= 0) return principal / months;

    final monthlyRate = annualRate / 12 / 100;
    final factor = _pow(1 + monthlyRate, months);
    final emi = principal * monthlyRate * factor / (factor - 1);
    return double.parse(emi.toStringAsFixed(2));
  }

  static double _pow(double base, int exponent) {
    double result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= base;
    }
    return result;
  }
}


