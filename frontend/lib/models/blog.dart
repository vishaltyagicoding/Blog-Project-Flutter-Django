import 'user.dart';

class Blog {
  final int id;
  final String title;
  final String? content;
  final String status;
  final User author;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BlogComment> comments;

  Blog({
    required this.id,
    required this.title,
    this.content,
    required this.status,
    required this.author,
    required this.createdAt,
    required this.updatedAt,
    this.comments = const [],
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String?,
      status: json['status'] as String,
      author: User.fromJson(json['author'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      comments: (json['comments'] as List?)
              ?.map((c) => BlogComment.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'status': status,
      'author': author.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }
}

class BlogComment {
  final int id;
  final User author;
  final String content;
  final DateTime createdAt;

  BlogComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    return BlogComment(
      id: json['id'] as int,
      author: User.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author': author.toJson(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BlogStatistics {
  final int total;

  BlogStatistics({
    required this.total,
  });

  factory BlogStatistics.fromJson(Map<String, dynamic> json) {
    return BlogStatistics(
      total: (json['total'] as int?) ?? 0,
    );
  }
}
