// lib/widgets/task_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:odak_list/models/task.dart';
import 'package:odak_list/utils/app_colors.dart';
import 'package:odak_list/utils/app_styles.dart';
import 'package:provider/provider.dart'; 
import 'package:odak_list/theme_provider.dart';
import 'package:odak_list/task_provider.dart';

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
      case 2: return AppColors.priorityHigh;   // Kırmızı (Yüksek)
      case 1: return AppColors.priorityMedium; // Turuncu (Orta)
      case 0: return Colors.blueAccent;        // Mavi (Düşük - Rengi değiştirdim daha net olsun diye)
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subTextColor = isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final Color priorityColor = _getPriorityColor(task.priority);
    final bool hasTime = task.dueDate != null && (task.dueDate!.hour != 0 || task.dueDate!.minute != 0);
    
    // Okunmamış mesaj var mı?
    final bool hasUnread = taskProvider.hasUnreadComments(task);
    
    // Görev kime ait?
    final String? assignedName = taskProvider.getMemberName(task.assignedMemberId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Padding'i kaldırdık çünkü sol şerit kenara yapışmalı
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16), // Köşeleri yuvarla
          boxShadow: isDarkMode ? [] : AppStyles.softShadow,
          border: isDarkMode ? Border.all(color: Colors.white10) : null,
        ),
        clipBehavior: Clip.antiAlias, // Şeridin taşmaması için kes
        child: IntrinsicHeight( // İçerik kadar yükseklik
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- 1. SOL ÖNCELİK ŞERİDİ ---
              Container(
                width: 6, // Şerit kalınlığı
                color: priorityColor,
              ),

              // --- 2. İÇERİK ALANI ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CHECKBOX
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: GestureDetector(
                          onTap: onToggleDone,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: task.isDone ? themeProvider.secondaryColor : Colors.transparent,
                              border: Border.all(
                                color: task.isDone ? themeProvider.secondaryColor : (isDarkMode ? Colors.grey : Colors.grey.shade400),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: task.isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // METİNLER VE ROZETLER
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BAŞLIK VE MESAJ UYARISI
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: task.isDone ? subTextColor : textColor,
                                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                                      decorationColor: subTextColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // YENİ MESAJ VARSA (Kırmızı Balon)
                                if (hasUnread) 
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.redAccent, width: 1),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.mark_chat_unread, size: 14, color: Colors.redAccent),
                                        SizedBox(width: 4),
                                        Text("Yeni", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                      ],
                                    ),
                                  )
                              ],
                            ),
                            
                            const SizedBox(height: 6),

                            // ALT BİLGİLER (Kime Atandı, Tekrar, Etiket)
                            Row(
                              children: [
                                // Kime Atandı?
                                if (assignedName != null) ...[
                                  CircleAvatar(
                                    radius: 8,
                                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                                    child: Text(assignedName[0].toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(assignedName, style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 10),
                                ],

                                // Tekrar Bilgisi
                                if (task.recurrence != 'none') ...[
                                  Icon(Icons.repeat, size: 12, color: subTextColor),
                                  const SizedBox(width: 4),
                                ],

                                // İlk Etiket (Varsa)
                                if (task.tags.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: themeProvider.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                    child: Text("#${task.tags.first}", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: themeProvider.primaryColor)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // SAĞ TARAFTA TARİH
                      if (task.dueDate != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('dd').format(task.dueDate!),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: task.isDone ? subTextColor : textColor),
                              ),
                              Text(
                                DateFormat('MMM', 'tr_TR').format(task.dueDate!).toUpperCase(),
                                style: TextStyle(fontSize: 11, color: subTextColor),
                              ),
                              if (hasTime)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    DateFormat('HH:mm').format(task.dueDate!),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: themeProvider.secondaryColor),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}