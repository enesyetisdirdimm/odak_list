package com.mrenes.odaklist

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class OdakWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                
                // Flutter'dan gelen verileri al
                val dateStr = widgetData.getString("date_str", "Tarih Yok")
                val doneCount = widgetData.getInt("done_count", 0)
                val totalCount = widgetData.getInt("total_count", 1) // 0'a bölünme hatası olmasın diye 1
                
                // İlerleme Yüzdesini Hesapla
                var progress = 0
                if (totalCount > 0) {
                    progress = (doneCount * 100) / totalCount
                }

                // Motivasyon Mesajı Seç
                val message = when {
                    progress == 100 -> "Harikasın! 🎉"
                    progress >= 50 -> "Yarıladın! 🔥"
                    progress > 0 -> "Devam et! 💪"
                    else -> "Hadi Başlayalım! 🚀"
                }

                // Verileri Ekrana Bas
                setTextViewText(R.id.widget_date, dateStr)
                setTextViewText(R.id.widget_done_count, doneCount.toString())
                setTextViewText(R.id.widget_total_count, totalCount.toString())
                setTextViewText(R.id.widget_status_text, message)
                
                // Progress Bar'ı Güncelle
                setProgressBar(R.id.widget_progress_bar, 100, progress, false)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}