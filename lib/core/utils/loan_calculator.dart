import 'dart:math' as math;
import '../../data/models/loan_model.dart';

/// Precision loan calculator utilities
class LoanCalculator {
  /// Calculate simple interest: I = P × R × T
  static double simpleInterest({
    required double principal,
    required double annualRate,
    required int days,
  }) {
    if (principal <= 0 || annualRate <= 0 || days <= 0) return 0.0;
    final rate = annualRate / 100.0;
    final timeYears = days / 365.0;
    final result = principal * rate * timeYears;
    if (result.isNaN || result.isInfinite) return 0.0;
    return double.parse(result.toStringAsFixed(2));
  }

  /// Calculate compound interest: A = P(1 + r/n)^(nt) - P
  static double compoundInterest({
    required double principal,
    required double annualRate,
    required int days,
    required int compoundingFrequency,
  }) {
    if (annualRate <= 0 || days <= 0 || principal <= 0) return 0.0;
    if (compoundingFrequency <= 0) return 0.0;
    final rate = annualRate / 100.0;
    final n = compoundingFrequency;
    final timeYears = days / 365.0;
    final exponent = n * timeYears;
    final base = 1 + rate / n;

    final amount = principal * math.pow(base, exponent);
    if (amount.isNaN || amount.isInfinite) return 0.0;
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

  /// Calculate monthly EMI
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
    final factor = math.pow(1 + monthlyRate, months).toDouble();
    if (factor <= 1 || factor.isInfinite || factor.isNaN) {
      return double.parse((principal / months).toStringAsFixed(2));
    }
    final emi = principal * monthlyRate * factor / (factor - 1);
    if (emi.isNaN || emi.isInfinite) return 0.0;
    return double.parse(emi.toStringAsFixed(2));
  }
}


