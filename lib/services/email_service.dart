import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:http/http.dart' as http;

class EmailService {
  // --- AYARLAR ---
  
  // 1. MOBİL (SMTP)
  static const String _smtpEmail = 'cofocus.app@gmail.com';
  static const String _smtpPassword = 'ivbo vunw wclx tosz'; 
  
  // 2. WEB (GOOGLE SCRIPT)
  static const String _googleScriptUrl = 'https://script.google.com/macros/s/AKfycbzLQxIKMKOAiyXVBmDIW2j8gYAqv2OYdkR9Ovu-PyglwXK9YBeQ5eJBkmciGBk4Q4sSxw/exec'; 
  
  // 3. GÜVENLİK ANAHTARI (Google Script'teki ile AYNI olmalı)
  static const String _scriptSecret = "COFOCUS_2025_GIZLI_ANAHTAR"; 

  // ----------------

  static Future<void> _sendEmail({
    required List<String> recipients,
    required List<String> ccRecipients,
    required String subject,
    required String htmlContent,
  }) async {
    
    // SENARYO 1: WEB
    if (kIsWeb) {
      try {
        final response = await http.post(
          Uri.parse(_googleScriptUrl),
          // headers siliyoruz (CORS için)
          body: json.encode({
            'secret': _scriptSecret, // <--- ŞİFREYİ BURADA GÖNDERİYORUZ
            'to': recipients.join(","),
            'cc': ccRecipients.join(","),
            'subject': subject,
            'htmlBody': htmlContent,
          }),
        );
        
        if (response.statusCode == 200 || response.statusCode == 302) {
           // Scriptten dönen cevabı kontrol et ("Yetkisiz Erişim" mi?)
           if (response.body.contains("Yetkisiz Erişim")) {
             print("Web Mail Hatası: Şifre Yanlış!");
           } else {
             print('Web Mail Başarılı');
           }
        }
      } catch (e) {
        print('Web Mail Hatası: $e');
      }
    } 
    // SENARYO 2: MOBİL
    else {
      final smtpServer = gmail(_smtpEmail, _smtpPassword);
      final message = Message()
        ..from = Address(_smtpEmail, 'CoFocus App')
        ..recipients.addAll(recipients)
        ..ccRecipients.addAll(ccRecipients)
        ..subject = subject
        ..html = htmlContent;

      try {
        await send(message, smtpServer);
        print('Mobil Mail Başarılı');
      } catch (e) {
        print('Mobil Mail Hatası: $e');
      }
    }
  }

  // --- Fonksiyonların geri kalanı aynı ---
  
  static Future<void> sendTaskAssignmentEmail({
    required String toEmail,
    required String toName,
    required String ccEmail,
    required String taskTitle,
    required String assignerName,
  }) async {
    String safeAssignerName = (assignerName.isEmpty || assignerName == 'null') ? "Yönetici" : assignerName;

    String html = '''
      <div style="font-family: Arial, sans-serif; color: #333;">
        <h3>Merhaba $toName,</h3>
        <p><strong>$safeAssignerName</strong> tarafından sana yeni bir görev atandı.</p>
        <div style="padding: 15px; border-left: 4px solid #007bff; background-color: #f0f8ff; border-radius: 4px;">
          <h2 style="margin: 0; color: #0056b3;">$taskTitle</h2>
        </div>
        <hr style="border: 0; border-top: 1px solid #eee; margin: 20px 0;">
        <p style="color: #888; font-size: 12px;">CoFocus Bildirim</p>
      </div>
    ''';

    await _sendEmail(
      recipients: [toEmail],
      ccRecipients: [ccEmail],
      subject: 'Yeni Görev: $taskTitle',
      htmlContent: html,
    );
  }

  static Future<void> sendTaskCompletionEmail({
    required String taskTitle,
    required String assignerEmail,
    required String assigneeEmail,
    required String completerEmail,
  }) async {
    Set<String> uniqueRecipients = {assignerEmail, assigneeEmail, completerEmail};
    uniqueRecipients.removeWhere((email) => email.isEmpty);

    String html = '''
      <div style="font-family: Arial, sans-serif; color: #333;">
        <h3 style="color: #28a745;">Görev Tamamlandı! 🎉</h3>
        <div style="padding: 15px; border-left: 4px solid #28a745; background-color: #e8f5e9; border-radius: 4px;">
          <h2 style="margin: 0; color: #1e7e34;">$taskTitle</h2>
        </div>
        <ul style="background-color: #f8f9fa; padding: 15px; margin-top:10px;">
          <li>Veren: $assignerEmail</li>
          <li>Yapan: $assigneeEmail</li>
          <li>Bitiren: $completerEmail</li>
        </ul>
      </div>
    ''';

    await _sendEmail(
      recipients: uniqueRecipients.toList(),
      ccRecipients: [],
      subject: '✅ Görev Tamamlandı: $taskTitle',
      htmlContent: html,
    );
  }
}