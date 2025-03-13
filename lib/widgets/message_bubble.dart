// lib/widgets/message_bubble.dart
import 'package:ai_assistent_bluetooth/models/chat_message.dart';
import 'package:ai_assistent_bluetooth/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isSentByUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingS),
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: _getBubbleColor(),
          borderRadius: BorderRadius.circular(AppTheme.radiusL),
          boxShadow: AppTheme.lightShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loading indicator
            if (message.isLoading)
              const LinearProgressIndicator(),
            
            // Message text
            Text(
              message.message,
              style: AppTheme.bodyMedium.copyWith(
                color: _getTextColor(),
              ),
            ),
            
            // Timestamp
            const SizedBox(height: AppTheme.spacingS),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (message.isError)
                  Icon(
                    Icons.error_outline,
                    size: 14,
                    color: _getMetadataColor(),
                  ),
                if (message.isError)
                  const SizedBox(width: AppTheme.spacingXS),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: AppTheme.bodySmall.copyWith(
                    color: _getMetadataColor(),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBubbleColor() {
    if (message.isSentByUser) {
      return AppTheme.primaryColor;
    } else if (message.isError) {
      return AppTheme.errorColor.withOpacity(0.1);
    } else if (message.isLoading) {
      return AppTheme.secondaryColor.withOpacity(0.1);
    } else {
      return Colors.white;
    }
  }

  Color _getTextColor() {
    if (message.isSentByUser) {
      return Colors.white;
    } else if (message.isError) {
      return AppTheme.errorColor;
    } else {
      return AppTheme.textPrimary;
    }
  }

  Color _getMetadataColor() {
    if (message.isSentByUser) {
      return Colors.white.withOpacity(0.7);
    } else if (message.isError) {
      return AppTheme.errorColor.withOpacity(0.7);
    } else {
      return AppTheme.textSecondary.withOpacity(0.7);
    }
  }
}