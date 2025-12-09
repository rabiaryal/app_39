package com.example.app_039

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.*

class AppHomeWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: android.appwidget.AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.app_home_widget).apply {
                
                // Get data from shared preferences
                val ongoingCount = widgetData.getInt("ongoing_count", 0)
                val upcomingCount = widgetData.getInt("upcoming_count", 0)
                val ongoingEvents = widgetData.getString("ongoing_events", "No ongoing events") ?: "No ongoing events"
                val upcomingEvents = widgetData.getString("upcoming_events", "No upcoming events") ?: "No upcoming events"
                val lastUpdated = widgetData.getString("last_updated", "") ?: ""
                
                // Update UI elements
                setTextViewText(R.id.widget_ongoing_count, ongoingCount.toString())
                setTextViewText(R.id.widget_upcoming_count, upcomingCount.toString())
                setTextViewText(R.id.widget_ongoing_events, 
                    if (ongoingEvents == "No events") "No ongoing events" else ongoingEvents)
                setTextViewText(R.id.widget_upcoming_events, 
                    if (upcomingEvents == "No events") "No upcoming events" else upcomingEvents)
                
                // Format last updated time
                val formattedTime = try {
                    if (lastUpdated.isNotEmpty()) {
                        val date = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.getDefault()).parse(lastUpdated.substring(0, 19))
                        val now = Date()
                        val diffInMinutes = ((now.time - (date?.time ?: 0)) / (1000 * 60)).toInt()
                        when {
                            diffInMinutes < 1 -> "Just now"
                            diffInMinutes < 60 -> "${diffInMinutes}m ago"
                            diffInMinutes < 1440 -> "${diffInMinutes / 60}h ago"
                            else -> "Yesterday"
                        }
                    } else {
                        "Never"
                    }
                } catch (e: Exception) {
                    "Unknown"
                }
                
                setTextViewText(R.id.widget_last_updated, formattedTime)
                
                // Create pending intent to open app
                val intent = Intent(context, MainActivity::class.java).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                
                // Set click intent for the whole widget
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}