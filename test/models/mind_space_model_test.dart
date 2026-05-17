import 'package:flutter_test/flutter_test.dart';
import 'package:beconscious/data/models/mind_space_model.dart';

void main() {
  group('MindSpaceItem', () {
    test('creates with defaults', () {
      final item = MindSpaceItem(id: 'm1', title: 'Remember this');
      expect(item.status, MindItemStatus.pending);
      expect(item.priority, MindItemPriority.medium);
      expect(item.description, isNull);
    });

    test('toJson/fromJson round-trip', () {
      final original = MindSpaceItem(
        id: 'm2',
        title: 'Buy milk',
        description: 'From the store nearby',
        priority: MindItemPriority.high,
        status: MindItemStatus.completed,
      );
      final json = original.toJson();
      final restored = MindSpaceItem.fromJson(json);
      expect(restored.id, 'm2');
      expect(restored.title, 'Buy milk');
      expect(restored.description, 'From the store nearby');
      expect(restored.priority, MindItemPriority.high);
      expect(restored.status, MindItemStatus.completed);
    });

    test('fromJson handles out-of-range status index', () {
      final json = {
        'id': 'm3',
        'title': 'Test',
        'status': 99, // out of range
        'priority': 0,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final item = MindSpaceItem.fromJson(json);
      expect(item.status, MindItemStatus.pending); // fallback
    });

    test('fromJson handles out-of-range priority index', () {
      final json = {
        'id': 'm4',
        'title': 'Test',
        'status': 0,
        'priority': -1, // out of range
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final item = MindSpaceItem.fromJson(json);
      expect(item.priority, MindItemPriority.medium); // fallback
    });

    test('fromJson handles missing status/priority', () {
      final json = {
        'id': 'm5',
        'title': 'Test',
        // status and priority missing
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      };
      final item = MindSpaceItem.fromJson(json);
      expect(item.status, MindItemStatus.pending);
      expect(item.priority, MindItemPriority.medium);
    });

    test('copyWith preserves unchanged fields', () {
      final original = MindSpaceItem(
        id: 'm6',
        title: 'Original',
        priority: MindItemPriority.low,
      );
      final updated = original.copyWith(title: 'Changed');
      expect(updated.title, 'Changed');
      expect(updated.priority, MindItemPriority.low);
      expect(updated.id, 'm6');
    });
  });
}

