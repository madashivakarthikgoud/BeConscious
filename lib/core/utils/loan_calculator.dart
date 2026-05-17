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
    if (principal <= 0 || annualRate <= 0 || days <= 0) return 0.0;
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
    if (annualRate <= 0 || days <= 0 || principal <= 0) return 0.0;
    final rate = annualRate / 100.0;
    final n = compoundingFrequency;
    final timeYears = days / 365.0;
    final exponent = n * timeYears;
    final base = 1 + rate / n;

    // Precise calculation using iterative approach
    final intPart = exponent.truncate();
    final fracPart = exponent - intPart;
    double factor = 1.0;
    for (int i = 0; i < intPart; i++) {
      factor *= base;
    }
    if (fracPart > 0.0001) {
      // base^frac approximation via exp(frac*ln(base))
      final lnBase = _lnApprox(base);
      factor *= _expApprox(fracPart * lnBase);
    }

    final amount = principal * factor;
    return double.parse((amount - principal).toStringAsFixed(2));
  }

  static double _lnApprox(double x) {
    if (x <= 0) return 0;
    final z = (x - 1) / (x + 1);
    double sum = 0, term = z;
    for (int i = 1; i <= 50; i += 2) {
      sum += term / i;
      term *= z * z;
    }
    return 2 * sum;
  }

  static double _expApprox(double x) {
    double sum = 1.0, term = 1.0;
    for (int i = 1; i <= 30; i++) {
      term *= x / i;
      sum += term;
      if (term.abs() < 1e-15) break;
    }
    return sum;
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
    if (principal <= 0) return 0.0;
    if (months <= 0) return principal;
    if (annualRate <= 0) return double.parse((principal / months).toStringAsFixed(2));

    final monthlyRate = annualRate / 12 / 100;
    final factor = _pow(1 + monthlyRate, months);
    if (factor <= 1) return double.parse((principal / months).toStringAsFixed(2));
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


