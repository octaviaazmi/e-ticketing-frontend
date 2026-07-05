import 'user.dart';

class Comment {
  final int id;
  final int ticketId;
  final int userId;
  final String text;
  final DateTime createdAt;
  final User? user;

  Comment({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.user,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      ticketId: json['ticket_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      text: json['text'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
}