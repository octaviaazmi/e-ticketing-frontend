import 'user.dart';
import 'comment.dart';

class Ticket {
  final int id;
  final String title;
  final String category;
  final String priority;
  final String status;
  final String description;
  final int createdBy;
  final int? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? createdByUser;
  final User? assignedToUser;
  final List<Comment> comments;
  final List<TicketHistory> histories;
  final List<String> attachments;

  Ticket({
    required this.id,
    required this.title,
    required this.category,
    required this.priority,
    required this.status,
    required this.description,
    required this.createdBy,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.createdByUser,
    this.assignedToUser,
    this.comments = const [],
    this.histories = const [],
    this.attachments = const [],
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    int _extractId(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is Map) {
        return value['id'] ?? 0;
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    // ========== 🔥 PERBAIKAN: Parse User dengan casting ==========
    User? _parseUser(dynamic value) {
      if (value == null) return null;
      if (value is Map) {
        // Cast ke Map<String, dynamic>
        return User.fromJson(Map<String, dynamic>.from(value));
      }
      return null;
    }

    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Ticket(
      id: json['id'] ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'medium',
      status: json['status']?.toString() ?? 'open',
      description: json['description']?.toString() ?? '',
      createdBy: _extractId(json['created_by']),
      assignedTo: json['assigned_to'] != null ? _extractId(json['assigned_to']) : null,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      createdByUser: _parseUser(json['created_by']),
      assignedToUser: _parseUser(json['assigned_to']),
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => Comment.fromJson(c)).toList()
          : [],
      histories: json['histories'] != null
          ? (json['histories'] as List).map((h) => TicketHistory.fromJson(h)).toList()
          : [],
      attachments: json['attachments'] != null
          ? (json['attachments'] as List).map((a) => a.toString()).toList()
          : [],
    );
  }
}

class TicketHistory {
  final int id;
  final int ticketId;
  final String status;
  final String? note;
  final DateTime createdAt;

  TicketHistory({
    required this.id,
    required this.ticketId,
    required this.status,
    this.note,
    required this.createdAt,
  });

  factory TicketHistory.fromJson(Map<String, dynamic> json) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return TicketHistory(
      id: json['id'] ?? 0,
      ticketId: json['ticket_id'] ?? 0,
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }
}