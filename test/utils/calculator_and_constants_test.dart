import 'package:flutter_test/flutter_test.dart';
import 'package:beconscious/core/utils/loan_calculator.dart';
import 'package:beconscious/core/constants/app_constants.dart';

void main() {
  group('LoanCalculator', () {
    group('simpleInterest', () {
      test('basic calculation', () {
        final result = LoanCalculator.simpleInterest(
          principal: 10000,
          annualRate: 12,
          days: 365,
        );
        expect(result, 1200.0);
      });

      test('returns 0 for zero principal', () {
        expect(LoanCalculator.simpleInterest(
            principal: 0, annualRate: 12, days: 365), 0.0);
      });

      test('returns 0 for zero rate', () {
        expect(LoanCalculator.simpleInterest(
            principal: 10000, annualRate: 0, days: 365), 0.0);
      });

      test('returns 0 for zero days', () {
        expect(LoanCalculator.simpleInterest(
            principal: 10000, annualRate: 12, days: 0), 0.0);
      });

      test('returns 0 for negative inputs', () {
        expect(LoanCalculator.simpleInterest(
            principal: -10000, annualRate: 12, days: 365), 0.0);
      });

      test('fractional days', () {
        final result = LoanCalculator.simpleInterest(
          principal: 10000,
          annualRate: 12,
          days: 30,
        );
        // 10000 * 0.12 * (30/365) ≈ 98.63
        expect(result, closeTo(98.63, 0.01));
      });
    });

    group('compoundInterest', () {
      test('monthly compounding for 1 year', () {
        final result = LoanCalculator.compoundInterest(
          principal: 10000,
          annualRate: 12,
          days: 365,
          compoundingFrequency: 12,
        );
        // 10000 * (1.01)^12 - 10000 ≈ 1268.25
        expect(result, closeTo(1268.25, 1));
      });

      test('daily compounding for 1 year', () {
        final result = LoanCalculator.compoundInterest(
          principal: 10000,
          annualRate: 12,
          days: 365,
          compoundingFrequency: 365,
        );
        // 10000 * (1 + 0.12/365)^365 - 10000 ≈ 1274.74
        expect(result, closeTo(1274.74, 1));
      });

      test('yearly compounding', () {
        final result = LoanCalculator.compoundInterest(
          principal: 10000,
          annualRate: 12,
          days: 365,
          compoundingFrequency: 1,
        );
        expect(result, closeTo(1200, 5)); // ~1200 for 1 year yearly
      });

      test('returns 0 for zero compounding frequency', () {
        expect(LoanCalculator.compoundInterest(
          principal: 10000,
          annualRate: 12,
          days: 365,
          compoundingFrequency: 0,
        ), 0.0);
      });

      test('returns 0 for zero principal', () {
        expect(LoanCalculator.compoundInterest(
          principal: 0,
          annualRate: 12,
          days: 365,
          compoundingFrequency: 12,
        ), 0.0);
      });
    });

    group('calculateEMI', () {
      test('basic EMI calculation', () {
        final emi = LoanCalculator.calculateEMI(
          principal: 100000,
          annualRate: 12,
          months: 12,
        );
        // EMI for 1L at 12% for 12 months ≈ 8884.88
        expect(emi, closeTo(8884.88, 1));
      });

      test('zero interest rate divides equally', () {
        final emi = LoanCalculator.calculateEMI(
          principal: 12000,
          annualRate: 0,
          months: 12,
        );
        expect(emi, 1000.0);
      });

      test('zero months returns principal', () {
        expect(LoanCalculator.calculateEMI(
          principal: 10000,
          annualRate: 12,
          months: 0,
        ), 10000);
      });

      test('zero principal returns 0', () {
        expect(LoanCalculator.calculateEMI(
          principal: 0,
          annualRate: 12,
          months: 12,
        ), 0.0);
      });
    });
  });

  group('AppConstants', () {
    group('formatCurrency', () {
      test('formats normal amount', () {
        expect(AppConstants.formatCurrency(1234.56), contains('1,234.56'));
      });

      test('handles NaN', () {
        expect(AppConstants.formatCurrency(double.nan), '₹0.00');
      });

      test('handles Infinity', () {
        expect(AppConstants.formatCurrency(double.infinity), '₹0.00');
      });

      test('handles negative Infinity', () {
        expect(AppConstants.formatCurrency(double.negativeInfinity), '₹0.00');
      });

      test('handles zero', () {
        expect(AppConstants.formatCurrency(0), contains('0.00'));
      });
    });

    group('formatCurrencyShort', () {
      test('formats crores', () {
        expect(AppConstants.formatCurrencyShort(15000000), contains('Cr'));
      });

      test('formats lakhs', () {
        expect(AppConstants.formatCurrencyShort(250000), contains('L'));
      });

      test('formats thousands', () {
        expect(AppConstants.formatCurrencyShort(5000), contains('K'));
      });

      test('handles NaN', () {
        expect(AppConstants.formatCurrencyShort(double.nan), '₹0');
      });

      test('handles negative amounts', () {
        final result = AppConstants.formatCurrencyShort(-250000);
        expect(result, startsWith('-'));
      });
    });

    group('formatDateShort', () {
      test('formats today', () {
        expect(AppConstants.formatDateShort(DateTime.now()), 'Today');
      });

      test('formats yesterday', () {
        expect(AppConstants.formatDateShort(
          DateTime.now().subtract(const Duration(days: 1)),
        ), 'Yesterday');
      });

      test('formats tomorrow', () {
        expect(AppConstants.formatDateShort(
          DateTime.now().add(const Duration(days: 1)),
        ), 'Tomorrow');
      });
    });
  });
}

