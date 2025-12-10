// Dosya: lib/screens/team_screen.dart

import 'package:flutter/material.dart';
import 'package:odak_list/models/team_member.dart';
import 'package:odak_list/services/database_service.dart';
import 'package:odak_list/task_provider.dart';
import 'package:odak_list/screens/premium_screen.dart'; // Premium Kontrolü İçin
import 'package:provider/provider.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  // YENİ: DÜZENLEME DİYALOĞU
  // DÜZENLEME VE YETKİ DİYALOĞU (GÜNCELLENMİŞ HALİ)
  void _showEditMemberDialog(BuildContext context, TeamMember member) {
    final nameController = TextEditingController(text: member.name);
    final emailController = TextEditingController(text: member.email);
    final pinController = TextEditingController(text: member.profilePin);

    // Yetki verilerini geçici değişkenlere alalım
    bool tempCanSeeAll = member.canSeeAllProjects;
    List<String> tempAllowedIds = List.from(member.allowedProjectIds);

    // Projeleri çekmek için Provider'a erişiyoruz
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final allProjects = taskProvider.projects; 

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("${member.name} Düzenle"),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 1. PROFİL BİLGİLERİ ---
                    const Text("Profil Bilgileri", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "İsim", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: "E-posta", border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: pinController,
                      decoration: const InputDecoration(
                        labelText: "Profil Pini (4 Hane)",
                        hintText: "Boşsa şifresiz",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                    ),
                    
                    const Divider(height: 30, thickness: 2),

                    // --- 2. PROJE YETKİLERİ ---
                    const Text("Erişim Yetkileri", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    
                    SwitchListTile(
                      title: const Text("Tüm Projeleri Gör", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Aktifse her şeye erişir."),
                      value: tempCanSeeAll,
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() => tempCanSeeAll = val);
                      },
                    ),

                    if (!tempCanSeeAll) ...[
                      const SizedBox(height: 10),
                      const Text("Sadece Seçilenleri Görsün:", style: TextStyle(fontSize: 12)),
                      Container(
                        height: 150, // Liste çok uzamasın diye sınırladık
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: allProjects.isEmpty 
                          ? const Center(child: Text("Hiç proje yok."))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: allProjects.length,
                              itemBuilder: (context, index) {
                                final project = allProjects[index];
                                final isSelected = tempAllowedIds.contains(project.id);
                                return CheckboxListTile(
                                  title: Text(project.title, style: const TextStyle(fontSize: 14)),
                                  value: isSelected,
                                  dense: true,
                                  activeColor: Colors.blue,
                                  onChanged: (val) {
                                    setState(() {
                                      if (val == true) {
                                        tempAllowedIds.add(project.id!);
                                      } else {
                                        tempAllowedIds.remove(project.id);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                      ),
                    ] else 
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                        child: const Row(children: [Icon(Icons.info, size: 16, color: Colors.blue), SizedBox(width: 5), Expanded(child: Text("Kullanıcı tam yetkili.", style: TextStyle(color: Colors.blue, fontSize: 12)))])
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    String? newPin = pinController.text.isEmpty ? null : pinController.text;
                    String? newEmail = emailController.text.isEmpty ? null : emailController.text.trim();

                    // 1. Profil Bilgilerini Güncelle
                    await DatabaseService().updateTeamMemberInfo(member.id, nameController.text, newPin, newEmail);
                    
                    // 2. Yetkileri Güncelle
                    await DatabaseService().updateTeamMemberPermissions(member.id, tempCanSeeAll, tempAllowedIds);
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı ve yetkiler güncellendi!")));
                    }
                  }
                },
                child: const Text("Kaydet"),
              )
            ],
          );
        }
      ),
    );
  }

  // YENİ KİŞİ EKLEME (Mevcut kodun aynısı, sadece premium kontrolü eklendi)
  void _addMemberFromSettings(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
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
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "E-posta (İsteğe bağlı)", border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
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
                   String? email = emailController.text.isEmpty ? null : emailController.text.trim();
                    DatabaseService().addTeamMember(nameController.text, selectedRole, pin,email);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // PREMIUM KONTROLÜ (3 Kişi Sınırı)
          bool isPremium = await dbService.checkPremiumStatus();
          var membersSnapshot = await dbService.getTeamMembersCollection().get();
          int memberCount = membersSnapshot.docs.length;

          if (!isPremium && memberCount >= 3) {
             if (context.mounted) {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
             }
             return;
          }

          if (context.mounted) {
            _addMemberFromSettings(context);
          }
        },
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
                        child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : "?", style: TextStyle(color: isMe ? Colors.white : Colors.black)),
                      ),
                      if (hasPin) const Positioned(right: 0, bottom: 0, child: Icon(Icons.lock, size: 14))
                    ],
                  ),
                  title: Text("${member.name} ${isMe ? '(Sen)' : ''}", style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(hasPin ? "Şifreli • ${member.role}" : "Şifresiz • ${member.role}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      IconButton(
      icon: Icon(
        Icons.vpn_key, 
        color: member.canSeeAllProjects ? Colors.green : Colors.orange
      ),
      tooltip: "Proje Erişim Yetkileri",
      onPressed: () => _showPermissionDialog(context, member),
    ),
                      // ROL DEĞİŞTİRME (Dropdown)
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
                      
                      // YENİ: DÜZENLEME BUTONU (Kalem)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditMemberDialog(context, member),
                      ),

                      // SİLME BUTONU
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

  void _showPermissionDialog(BuildContext context, TeamMember member) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    // Admin olduğumuz için _allProjectsRaw yerine direkt projects'i kullanabiliriz (Admin her şeyi görür)
    final allProjects = taskProvider.projects; 

    // Geçici değişkenler
    bool tempCanSeeAll = member.canSeeAllProjects;
    List<String> tempAllowedIds = List.from(member.allowedProjectIds);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("${member.name} Erişimi"),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. TÜMÜNÜ GÖR SEÇENEĞİ
                      SwitchListTile(
                        title: const Text("Tüm Projeleri Gör", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Aktifse aşağıdakilere bakılmaksızın her şeye erişir."),
                        value: tempCanSeeAll,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setState(() => tempCanSeeAll = val);
                        },
                      ),
                      const Divider(),
                      
                      // 2. TEK TEK SEÇME LİSTESİ
                      if (tempCanSeeAll)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 10),
                              Expanded(child: Text("Kullanıcı şu an tam yetkili.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        )
                      else ...[
                         const Align(
                           alignment: Alignment.centerLeft,
                           child: Text("Sadece Seçilenleri Görsün:", style: TextStyle(fontWeight: FontWeight.bold)),
                         ),
                         const SizedBox(height: 10),
                         if (allProjects.isEmpty)
                           const Text("Henüz proje yok.")
                         else
                           ...allProjects.map((project) {
                             final isSelected = tempAllowedIds.contains(project.id);
                             return CheckboxListTile(
                               title: Text(project.title),
                               value: isSelected,
                               dense: true,
                               onChanged: (val) {
                                 setState(() {
                                   if (val == true) {
                                     tempAllowedIds.add(project.id!);
                                   } else {
                                     tempAllowedIds.remove(project.id);
                                   }
                                 });
                               },
                             );
                           }).toList(),
                      ]
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                ElevatedButton(
                  onPressed: () async {
                    // Kaydet
                    await DatabaseService().updateTeamMemberPermissions(
                      member.id, 
                      tempCanSeeAll, 
                      tempAllowedIds
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yetkiler güncellendi!")));
                    }
                  },
                  child: const Text("Kaydet"),
                )
              ],
            );
          },
        );
      },
    );
  }
}