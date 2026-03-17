import 'package:flutter/material.dart';

/// A circular avatar showing the first letter of [username].
/// Optionally shows [subtitle] below the name (e.g. a date string).
class AuthorAvatar extends StatelessWidget {
  final String username;
  final String? subtitle;
  final double radius;

  const AuthorAvatar({
    super.key,
    required this.username,
    this.subtitle,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: primary.withValues(alpha: 0.15),
      child: Text(
        username[0].toUpperCase(),
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
        ),
      ),
    );

    if (subtitle == null) return avatar;

    return Row(
      children: [
        avatar,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(username,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ],
    );
  }
}
