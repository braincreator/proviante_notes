import 'package:isar/isar.dart';

part 'note.g.dart';

@collection
// Represents a single note entry.
class Note {
  Id id = Isar.autoIncrement; // Auto incrementing ID

  @Index()
  late String title;
  late String text;
  @Index() // Add index annotation
  late DateTime createdAt;
  @Index()
  late DateTime updatedAt; // Added updatedAt field

  // Default constructor (optional, Isar can handle it)
  Note();

  // Constructor for creating instances manually (useful for Bloc)
  Note.create({
    required this.title,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    // id is auto-incremented by Isar, so not included here
  });

  // copyWith method for easy updates
  Note copyWith({
    Id? id, // Allow copying ID if needed, though usually not modified
    String? title,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // Create a new instance and copy values
    final newNote = Note()
      ..id = id ?? this.id
      ..title = title ?? this.title
      ..text = text ?? this.text
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
    return newNote;
  }
}