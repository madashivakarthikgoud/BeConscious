import 'package:flutter_test/flutter_test.dart';
import 'package:beconscious/data/models/savings_model.dart';

void main() {
  group('SavingsGoalModel', () {
    test('totalSaved is sum of contributions', () {
      final goal = SavingsGoalModel(
        id: 's1',
        name: 'Vacation',
        targetAmount: 10000,
        deadline: DateTime(2027, 1, 1),
        contributions: [
          SavingsContribution(id: 'c1', amount: 2000, date: DateTime(2026, 1, 1)),
          SavingsContribution(id: 'c2', amount: 3000, date: DateTime(2026, 2, 1)),
        ],
      );
      expect(goal.totalSaved, 5000);
    });

    test('progressPercent clamps to 1.0', () {
      final goal = SavingsGoalModel(
        id: 's2',
        name: 'Fund',
        targetAmount: 100,
        deadline: DateTime(2027, 1, 1),
        contributions: [
          SavingsContribution(id: 'c1', amount: 200, date: DateTime.now()),
        ],
      );
      expect(goal.progressPercent, 1.0);
    });

    test('progressPercent is 0.0 when targetAmount is 0', () {
      final goal = SavingsGoalModel(
        id: 's3',
        name: 'Empty',
        targetAmount: 0,
        deadline: DateTime(2027, 1, 1),
      );
      expect(goal.progressPercent, 0.0);
    });

    test('remainingAmount never goes negative', () {
      final goal = SavingsGoalModel(
        id: 's4',
        name: 'Over',
        targetAmount: 100,
        deadline: DateTime(2027, 1, 1),
        contributions: [
          SavingsContribution(id: 'c1', amount: 500, date: DateTime.now()),
        ],
      );
      expect(goal.remainingAmount, 0.0);
    });

    test('requiredPerDay returns 0 when overdue', () {
      final goal = SavingsGoalModel(
        id: 's5',
        name: 'Overdue',
        targetAmount: 10000,
        deadline: DateTime(2020, 1, 1), // past
      );
      expect(goal.requiredPerDay, 0.0);
    });

    test('requiredPerDay returns 0 when fully saved', () {
      final goal = SavingsGoalModel(
        id: 's6',
        name: 'Done',
        targetAmount: 100,
        deadline: DateTime(2027, 1, 1),
        contributions: [
          SavingsContribution(id: 'c1', amount: 100, date: DateTime.now()),
        ],
      );
      expect(goal.requiredPerDay, 0.0);
    });

    test('requiredPerMonth returns 0 when overdue', () {
      final goal = SavingsGoalModel(
        id: 's7',
        name: 'Overdue',
        targetAmount: 10000,
        deadline: DateTime(2020, 1, 1),
      );
      expect(goal.requiredPerMonth, 0.0);
    });

    test('fromJson handles corrupted contributions', () {
      final json = {
        'id': 's8',
        'name': 'Test',
        'targetAmount': 1000,
        'deadline': '2027-01-01T00:00:00.000Z',
        'contributions': [
          {'id': 'c1', 'amount': 100, 'date': '2026-01-01T00:00:00.000Z'},
          {'bad': 'data'}, // corrupted
        ],
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final goal = SavingsGoalModel.fromJson(json);
      expect(goal.contributions.length, 1);
    });

    test('toJson/fromJson round-trip', () {
      final original = SavingsGoalModel(
        id: 's9',
        name: 'Emergency Fund',
        targetAmount: 50000,
        deadline: DateTime(2027, 6, 1),
        colorValue: 0xFF2196F3,
        contributions: [
          SavingsContribution(id: 'c1', amount: 10000, date: DateTime(2026, 3, 1)),
        ],
      );
      final json = original.toJson();
      final restored = SavingsGoalModel.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.targetAmount, original.targetAmount);
      expect(restored.colorValue, 0xFF2196F3);
      expect(restored.contributions.length, 1);
    });
  });

  group('SavingsContribution', () {
    test('toJson/fromJson round-trip', () {
      final c = SavingsContribution(
        id: 'c1',
        amount: 500,
        date: DateTime(2026, 5, 1),
        notes: 'Monthly savings',
      );
      final json = c.toJson();
      final restored = SavingsContribution.fromJson(json);
      expect(restored.id, 'c1');
      expect(restored.amount, 500);
      expect(restored.notes, 'Monthly savings');
    });
  });
}

