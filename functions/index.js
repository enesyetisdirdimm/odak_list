/**
 * Modern (V1) FCM API Kullanan Cloud Function
 * "sendToDevice" yerine "send" kullanılarak 404 hatası giderilmiştir.
 */

const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');

admin.initializeApp();

exports.sendTaskNotification = functions.firestore
  .document('tasks/{taskId}')
  .onWrite(async (change, context) => {
    
    // Veri silindiyse işlem yapma
    if (!change.after.exists) return null;

    const task = change.after.data();
    const previousTask = change.before.data();

    // Veri yoksa çık
    if (!task) return null;

    // KONTROL: Yeni bir atama mı?
    if (task.assignedMemberId && task.assignedMemberId !== previousTask?.assignedMemberId) {
        
        const creatorId = task.creatorId; 
        const assignedMemberId = task.assignedMemberId;

        console.log(`Yeni Atama: ${creatorId} -> ${assignedMemberId}`);

        try {
            // 1. Premium Kontrolü
            const userSnapshot = await admin.firestore().collection('users').doc(creatorId).get();
            const userData = userSnapshot.data();

            if (!userData || userData.isPremium !== true) {
                console.log(`⛔ Bildirim iptal. Kullanıcı ${creatorId} Premium değil.`);
                return null;
            }

            // 2. Token Bulma
            const memberSnapshot = await admin.firestore()
                .collection('users').doc(creatorId)
                .collection('members').doc(assignedMemberId)
                .get();

            if (!memberSnapshot.exists) {
                console.log("❌ HATA: Atanan üye profili bulunamadı.");
                return null;
            }

            const memberData = memberSnapshot.data();
            const fcmToken = memberData.fcmToken;

            // 3. Gönderme (MODERN API FORMATI)
            if (fcmToken) {
                
                // Mesaj formatı çok önemlidir!
                const message = {
                    token: fcmToken, // Token artık buraya yazılıyor
                    notification: {
                        title: '🎯 Yeni Görev Atandı!',
                        body: `${task.title} görevi sana verildi. Hemen göz at!`
                    },
                    data: {
                        taskId: context.params.taskId,
                        click_action: 'FLUTTER_NOTIFICATION_CLICK',
                        sound: 'default' 
                    }
                };

                // sendToDevice YERİNE send KULLANIYORUZ
                await admin.messaging().send(message);
                console.log("✅ PREMIUM BİLDİRİM GÖNDERİLDİ! (V1 API)");
            } else {
                console.log("⚠️ Kullanıcının FCM Token'ı yok. (Hiç giriş yapmamış)");
            }

        } catch (error) {
            console.error("🔥 BİLDİRİM HATASI:", error);
            
            // Eğer token geçersizse (Unregistered) veritabanından silebiliriz (Opsiyonel)
            if (error.code === 'messaging/registration-token-not-registered') {
                console.log("Token geçersiz, temizlenmesi gerekebilir.");
            }
        }
    }
    return null;
});