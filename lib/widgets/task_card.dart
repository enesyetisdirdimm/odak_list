// lib/widgets/task_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:odak_list/utils/app_styles.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final Map<String, Color> categories;
  final VoidCallback onToggleDone;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.categories,
    required this.onToggleDone,
    required this.onTap,
  });

  // YENİ: Aciliyet rengini belirleyen yardımcı metot
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return AppColors.priorityHigh;
      case 1:
        return AppColors.priorityMedium;
      case 0:
        return AppColors.priorityLow;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = categories[task.category] ?? Colors.grey;
    final Color priorityColor = _getPriorityColor(task.priority); // <-- YENİ

    final bool hasTime = task.dueDate != null &&
        (task.dueDate!.hour != 0 || task.dueDate!.minute != 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppStyles.softShadow,
          // YENİ: Sol kenara renkli aciliyet çizgisi
          border: Border(
            left: BorderSide(
              color: priorityColor,
              width: 5,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8), // Renkli kenarlık için boşluk
            // Checkbox
            GestureDetector(
              onTap: onToggleDone,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: task.isDone ? categoryColor : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: categoryColor, width: 2),
                ),
                child: task.isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // Görev Başlığı ve Kategori
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: task.isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      decoration: task.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (task.category != null)
                    Chip(
                      label: Text(
                        task.category!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: categoryColor,
                      padding: const EdgeInsets.all(0),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Tarih ve Saat
            if (task.dueDate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('dd').format(task.dueDate!),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(task.dueDate!).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (hasTime)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('HH:mm').format(task.dueDate!),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGradientEnd,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}