import 'package:flutter_test/flutter_test.dart';
import 'package:beconscious/data/models/loan_model.dart';

void main() {
  group('LoanModel', () {
    test('totalPaid is sum of payments', () {
      final loan = LoanModel(
        id: 'l1',
        type: LoanType.taken,
        personName: 'Alice',
        principalAmount: 10000,
        interestRate: 12,
        interestType: InterestType.simple,
        interestPeriod: InterestPeriod.yearly,
        startDate: DateTime(2025, 1, 1),
        payments: [
          LoanPayment(id: 'p1', amount: 2000, date: DateTime(2025, 6, 1)),
          LoanPayment(id: 'p2', amount: 3000, date: DateTime(2025, 12, 1)),
        ],
      );
      expect(loan.totalPaid, 5000.0);
    });

    test('simple interest calculation is correct', () {
      final loan = LoanModel(
        id: 'l2',
        type: LoanType.taken,
        personName: 'Bob',
        principalAmount: 10000,
        interestRate: 12,
        interestType: InterestType.simple,
        interestPeriod: InterestPeriod.yearly,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
      );
      // 10000 * 12/100 * 1 = 1200
      expect(loan.currentInterest, closeTo(1200, 5));
    });

    test('compound interest with monthly compounding', () {
      final loan = LoanModel(
        id: 'l3',
        type: LoanType.given,
        personName: 'Charlie',
        principalAmount: 10000,
        interestRate: 12,
        interestType: InterestType.compound,
        interestPeriod: InterestPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
      );
      // A = 10000 * (1 + 0.01)^12 - 10000 ≈ 1268.25
      expect(loan.currentInterest, closeTo(1268.25, 10));
    });

    test('zero days yields zero interest', () {
      final loan = LoanModel(
        id: 'l4',
        type: LoanType.taken,
        personName: 'Dave',
        principalAmount: 10000,
        interestRate: 12,
        interestType: InterestType.simple,
        interestPeriod: InterestPeriod.yearly,
        startDate: DateTime.now(),
      );
      expect(loan.currentInterest, 0.0);
    });

    test('zero interest rate yields zero interest', () {
      final loan = LoanModel(
        id: 'l5',
        type: LoanType.taken,
        personName: 'Eve',
        principalAmount: 10000,
        interestRate: 0,
        interestType: InterestType.compound,
        interestPeriod: InterestPeriod.monthly,
        startDate: DateTime.now().subtract(const Duration(days: 365)),
      );
      expect(loan.currentInterest, 0.0);
    });

    test('totalDueNow never goes negative', () {
      final loan = LoanModel(
        id: 'l6',
        type: LoanType.taken,
        personName: 'Frank',
        principalAmount: 1000,
        interestRate: 5,
        interestType: InterestType.simple,
        interestPeriod: InterestPeriod.yearly,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        payments: [
          LoanPayment(id: 'p1', amount: 999999, date: DateTime.now()),
        ],
      );
      expect(loan.totalDueNow, 0.0);
    });

    test('remainingPrincipal never goes negative', () {
      final loan = LoanModel(
        id: 'l7',
        type: LoanType.taken,
        personName: 'Grace',
        principalAmount: 1000,
        interestRate: 0,
        interestType: InterestType.simple,
        interestPeriod: InterestPeriod.yearly,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        payments: [
          LoanPayment(id: 'p1', amount: 5000, date: DateTime.now()),
        ],
      );
      expect(loan.remainingPrincipal, 0.0);
    });

    test('fromJson handles out-of-range enum indices', () {
      final json = {
        'id': 'l8',
        'type': 99,
        'personName': 'Test',
        'principalAmount': 1000,
        'interestRate': 5,
        'interestType': 99,
        'interestPeriod': 99,
        'startDate': '2026-01-01T00:00:00.000Z',
        'payments': <dynamic>[],
        'status': 99,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final loan = LoanModel.fromJson(json);
      expect(loan.type, LoanType.taken);
      expect(loan.interestType, InterestType.simple);
      expect(loan.interestPeriod, InterestPeriod.yearly);
      expect(loan.status, LoanStatus.active);
    });

    test('fromJson handles corrupted payment entries', () {
      final json = {
        'id': 'l9',
        'type': 0,
        'personName': 'Test',
        'principalAmount': 1000,
        'interestRate': 5,
        'interestType': 0,
        'interestPeriod': 0,
        'startDate': '2026-01-01T00:00:00.000Z',
        'payments': [
          {'id': 'p1', 'amount': 100, 'date': '2026-02-01T00:00:00.000Z'},
          {'bad': 'data'}, // corrupted
          {'id': 'p2', 'amount': 200, 'date': '2026-03-01T00:00:00.000Z'},
        ],
        'status': 0,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final loan = LoanModel.fromJson(json);
      expect(loan.payments.length, 2); // corrupted entry skipped
    });

    test('toJson/fromJson round-trip preserves data', () {
      final original = LoanModel(
        id: 'l10',
        type: LoanType.given,
        personName: 'Hannah',
        personContact: '9876543210',
        principalAmount: 50000,
        interestRate: 8.5,
        interestType: InterestType.compound,
        interestPeriod: InterestPeriod.monthly,
        startDate: DateTime(2026, 1, 1),
        expectedEndDate: DateTime(2027, 1, 1),
        payments: [
          LoanPayment(id: 'p1', amount: 5000, date: DateTime(2026, 6, 1), notes: 'First EMI'),
        ],
        status: LoanStatus.active,
        notes: 'Business loan',
      );
      final json = original.toJson();
      final restored = LoanModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.personName, original.personName);
      expect(restored.personContact, original.personContact);
      expect(restored.principalAmount, original.principalAmount);
      expect(restored.interestRate, original.interestRate);
      expect(restored.interestType, original.interestType);
      expect(restored.payments.length, 1);
      expect(restored.payments.first.notes, 'First EMI');
    });
  });

  group('LoanPayment', () {
    test('toJson/fromJson round-trip', () {
      final payment = LoanPayment(
        id: 'pay1',
        amount: 5000,
        date: DateTime(2026, 3, 15),
        notes: 'Partial payment',
      );
      final json = payment.toJson();
      final restored = LoanPayment.fromJson(json);
      expect(restored.id, 'pay1');
      expect(restored.amount, 5000);
      expect(restored.notes, 'Partial payment');
    });
  });
}

