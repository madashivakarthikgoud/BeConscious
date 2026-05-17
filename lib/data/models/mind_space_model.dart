enum MindItemStatus { pending, completed }

enum MindItemPriority { low, medium, high }

class MindSpaceItem {
  final String id;
  final String title;
  final String? description;
  final MindItemStatus status;
  final MindItemPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;

  MindSpaceItem({
    required this.id,
    required this.title,
    this.description,
    this.status = MindItemStatus.pending,
    this.priority = MindItemPriority.medium,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  MindSpaceItem copyWith({
    String? id,
    String? title,
    String? description,
    MindItemStatus? status,
    MindItemPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MindSpaceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.index,
        'priority': priority.index,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory MindSpaceItem.fromJson(Map<String, dynamic> json) => MindSpaceItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        status: MindItemStatus.values[json['status'] as int? ?? 0],
        priority: MindItemPriority.values[json['priority'] as int? ?? 1],
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      );
}

