package com.example.odak_list // DİKKAT: Kendi paket adınla aynı olmalı!

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
                val count = widgetData.getString("task_count", "0")
                val title = widgetData.getString("title", "OdakList")

                // Ekrana bas
                setTextViewText(R.id.widget_title, title)
                setTextViewText(R.id.widget_count, count)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}