class FurnitureItem {
  final String id;
  final String name;
  final String category;
  final String room;
  final String? imagePath;
  final double? widthCm;
  final double? heightCm;
  final String? notes;
  final DateTime createdAt;

  FurnitureItem({
    required this.id,
    required this.name,
    required this.category,
    required this.room,
    this.imagePath,
    this.widthCm,
    this.heightCm,
    this.notes,
    required this.createdAt,
  });

  double? get area {
    if (widthCm != null && heightCm != null) {
      return (widthCm! * heightCm!) / 10000; // Convert to square meters
    }
    return null;
  }

  String get displayDimensions {
    if (widthCm != null && heightCm != null) {
      return '${widthCm!.toStringAsFixed(1)} × ${heightCm!.toStringAsFixed(1)} cm';
    }
    return 'Not measured';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'room': room,
      'image_path': imagePath,
      'width_cm': widthCm,
      'height_cm': heightCm,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory FurnitureItem.fromMap(Map<String, dynamic> map) {
    return FurnitureItem(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      room: map['room'] as String,
      imagePath: map['image_path'] as String?,
      widthCm: map['width_cm'] as double?,
      heightCm: map['height_cm'] as double?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  FurnitureItem copyWith({
    String? id,
    String? name,
    String? category,
    String? room,
    String? imagePath,
    double? widthCm,
    double? heightCm,
    String? notes,
    DateTime? createdAt,
  }) {
    return FurnitureItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      room: room ?? this.room,
      imagePath: imagePath ?? this.imagePath,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'FurnitureItem(id: $id, name: $name, category: $category, room: $room)';
  }
}

class FurnitureCategory {
  static const List<String> categories = [
    'Sofa',
    'Chair',
    'Table',
    'Bed',
    'Storage',
    'Appliance',
    'Other',
  ];
}

class FurnitureRoom {
  static const List<String> rooms = [
    'Living Room',
    'Bedroom',
    'Kitchen',
    'Dining Room',
    'Bathroom',
    'Office',
    'Garage',
    'Basement',
    'Other',
  ];
}