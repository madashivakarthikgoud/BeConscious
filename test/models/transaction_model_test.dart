import 'package:flutter_test/flutter_test.dart';
import 'package:beconscious/data/models/transaction_model.dart';

void main() {
  group('TransactionModel', () {
    test('creates with required fields', () {
      final txn = TransactionModel(
        id: 'test-1',
        amount: 100.0,
        type: TransactionType.expense,
        dateTime: DateTime(2026, 1, 15),
        description: 'Lunch',
        moneySourcePerson: 'Self',
        beneficiaryPerson: 'Self',
        tags: ['Food'],
        paymentMode: PaymentMode.cash,
      );
      expect(txn.amount, 100.0);
      expect(txn.type, TransactionType.expense);
      expect(txn.tags, ['Food']);
    });

    test('toJson and fromJson round-trip', () {
      final original = TransactionModel(
        id: 'test-2',
        amount: 250.50,
        type: TransactionType.income,
        dateTime: DateTime(2026, 3, 10, 14, 30),
        description: 'Salary',
        notes: 'March salary',
        moneySourcePerson: 'Company',
        beneficiaryPerson: 'Self',
        tags: ['Salary', 'Work'],
        paymentMode: PaymentMode.bankTransfer,
      );
      final json = original.toJson();
      final restored = TransactionModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.amount, original.amount);
      expect(restored.type, original.type);
      expect(restored.description, original.description);
      expect(restored.notes, original.notes);
      expect(restored.tags, original.tags);
      expect(restored.paymentMode, original.paymentMode);
    });

    test('fromJson handles out-of-range type index gracefully', () {
      final json = {
        'id': 'test-3',
        'amount': 50,
        'type': 999, // out of range
        'dateTime': '2026-01-01T00:00:00.000Z',
        'description': 'Test',
        'moneySourcePerson': 'Self',
        'beneficiaryPerson': 'Self',
        'tags': <String>[],
        'paymentMode': 0,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final txn = TransactionModel.fromJson(json);
      expect(txn.type, TransactionType.expense); // fallback
    });

    test('fromJson handles out-of-range paymentMode index gracefully', () {
      final json = {
        'id': 'test-4',
        'amount': 50,
        'type': 0,
        'dateTime': '2026-01-01T00:00:00.000Z',
        'description': 'Test',
        'moneySourcePerson': 'Self',
        'beneficiaryPerson': 'Self',
        'tags': <String>[],
        'paymentMode': -1, // invalid
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final txn = TransactionModel.fromJson(json);
      expect(txn.paymentMode, PaymentMode.cash); // fallback
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'test-5',
        'amount': 10,
        'type': 1,
        'dateTime': '2026-05-01T00:00:00.000Z',
        'description': 'Test',
        'tags': <dynamic>[],
        'paymentMode': 0,
        'createdAt': '2026-05-01T00:00:00.000Z',
        'updatedAt': '2026-05-01T00:00:00.000Z',
      };
      final txn = TransactionModel.fromJson(json);
      expect(txn.moneySourcePerson, 'Self');
      expect(txn.beneficiaryPerson, 'Self');
      expect(txn.notes, isNull);
    });

    test('fromJson handles mixed-type tags list', () {
      final json = {
        'id': 'test-6',
        'amount': 10,
        'type': 0,
        'dateTime': '2026-05-01T00:00:00.000Z',
        'description': 'Test',
        'moneySourcePerson': 'Self',
        'beneficiaryPerson': 'Self',
        'tags': ['Food', 123, null, 'Shopping'], // mixed types
        'paymentMode': 0,
        'createdAt': '2026-05-01T00:00:00.000Z',
        'updatedAt': '2026-05-01T00:00:00.000Z',
      };
      final txn = TransactionModel.fromJson(json);
      expect(txn.tags, ['Food', 'Shopping']); // only strings
    });

    test('copyWith preserves unchanged fields', () {
      final original = TransactionModel(
        id: 'test-7',
        amount: 100.0,
        type: TransactionType.expense,
        dateTime: DateTime(2026, 1, 1),
        description: 'Original',
        moneySourcePerson: 'Self',
        beneficiaryPerson: 'Self',
        tags: ['Tag1'],
        paymentMode: PaymentMode.upi,
      );
      final updated = original.copyWith(amount: 200.0);
      expect(updated.amount, 200.0);
      expect(updated.description, 'Original');
      expect(updated.paymentMode, PaymentMode.upi);
    });
  });
}

