import 'package:flutter/material.dart';
import 'package:odak_list/models/team_member.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/task_provider.dart';
import 'package:provider/provider.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  // Yönetim ekranından yeni profil ekleme (Ayarların içinden)
  void _addMemberFromSettings(BuildContext context) {
    final nameController = TextEditingController();
    final pinController = TextEditingController();
    String selectedRole = 'editor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Ekibe Kişi Ekle"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "İsim")),
                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedRole,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'editor', child: Text("Editör")),
                    DropdownMenuItem(value: 'admin', child: Text("Yönetici")),
                  ],
                  onChanged: (val) => setState(() => selectedRole = val!),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: pinController,
                  decoration: const InputDecoration(labelText: "Şifre (Opsiyonel)", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    String? pin = pinController.text.isEmpty ? null : pinController.text;
                    DatabaseService().addTeamMember(nameController.text, selectedRole, pin);
                    Navigator.pop(ctx);
                  }
                },
                child: const Text("Ekle"),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = DatabaseService();
    final taskProvider = Provider.of<TaskProvider>(context);
    final currentMemberId = taskProvider.currentMember?.id;

    if (!taskProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text("Yetkisiz")),
        body: const Center(child: Text("Bu alanı sadece yöneticiler görebilir.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Ekip ve Roller")),
      // YENİ: Admin buradan da kişi ekleyebilmeli
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addMemberFromSettings(context),
        child: const Icon(Icons.person_add),
      ),
      body: StreamBuilder<List<TeamMember>>(
        stream: dbService.getTeamMembersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Hata"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final members = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final isMe = member.id == currentMemberId;
              final hasPin = member.profilePin != null && member.profilePin!.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        backgroundColor: isMe ? Colors.blueAccent : (member.role == 'admin' ? Colors.purple.shade100 : Colors.grey.shade300),
                        child: Text(member.name[0].toUpperCase(), style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                      ),
                      if (hasPin) const Positioned(right: 0, bottom: 0, child: Icon(Icons.lock, size: 14))
                    ],
                  ),
                  title: Text("${member.name} ${isMe ? '(Sen)' : ''}", style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(hasPin ? "Şifreli • ${member.role}" : "Şifresiz • ${member.role}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: member.role,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text("Yönetici")),
                          DropdownMenuItem(value: 'editor', child: Text("Editör")),
                        ],
                        onChanged: (newValue) async {
                          if (newValue != null && newValue != member.role) {
                            if (isMe) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kendinizi kısıtlayamazsınız.")));
                              return;
                            }
                            await dbService.updateTeamMemberRole(member.id, newValue);
                          }
                        },
                      ),
                      if (!isMe)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Silinsin mi?"), actions: [TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("İptal")), TextButton(onPressed: () async { await dbService.deleteTeamMember(member.id); Navigator.pop(ctx); }, child: const Text("Sil", style: TextStyle(color: Colors.red)))]));
                          },
                        )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}