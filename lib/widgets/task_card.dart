import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:odak_list/utils/app_styles.dart';
import 'package:provider/provider.dart'; 
import 'package:odak_list/theme_provider.dart';

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

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 2: return AppColors.priorityHigh;
      case 1: return AppColors.priorityMedium;
      case 0: return AppColors.priorityLow;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final Color priorityColor = _getPriorityColor(task.priority);
    final bool hasTime = task.dueDate != null && (task.dueDate!.hour != 0 || task.dueDate!.minute != 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDarkMode ? [] : AppStyles.softShadow,
          border: isDarkMode ? Border.all(color: Colors.white10) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // İçeriği yukarı hizala
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2.0), // Biraz aşağı al
              child: GestureDetector(
                onTap: onToggleDone,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: task.isDone ? themeProvider.secondaryColor : Colors.transparent,
                    border: Border.all(
                      color: task.isDone ? themeProvider.secondaryColor : (isDarkMode ? Colors.grey : Colors.grey.shade400),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: task.isDone
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // İçerik
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: task.isDone ? subTextColor : textColor,
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                      decorationColor: subTextColor,
                    ),
                  ),
                  
                  // Tekrar İkonu (Varsa)
                  if (task.recurrence != 'none')
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.repeat, size: 12, color: themeProvider.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            task.recurrence == 'daily' ? 'Her Gün' : (task.recurrence == 'weekly' ? 'Her Hafta' : 'Her Ay'),
                            style: TextStyle(fontSize: 10, color: subTextColor),
                          )
                        ],
                      ),
                    ),

                  // YENİ: Etiketler (Tags)
                  if (task.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: task.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: themeProvider.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "#$tag",
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: themeProvider.primaryColor),
                          ),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
            
            // Tarih ve Saat
            if (task.dueDate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Öncelik Noktası
                  Icon(Icons.circle, size: 8, color: priorityColor),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd').format(task.dueDate!),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: task.isDone ? subTextColor : textColor),
                  ),
                  Text(
                    DateFormat('MMM', 'tr_TR').format(task.dueDate!).toUpperCase(),
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),
                  if (hasTime)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('HH:mm').format(task.dueDate!),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: themeProvider.secondaryColor),
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