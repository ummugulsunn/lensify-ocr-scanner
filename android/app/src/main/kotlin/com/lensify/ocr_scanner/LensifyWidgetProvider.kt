package com.lensify.ocr_scanner

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.os.Build

/**
 * Lensify OCR Scanner Widget Provider
 * Provides quick access to OCR features from home screen
 */
class LensifyWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_CAMERA = "widget_camera"
        const val ACTION_GALLERY = "widget_gallery"
        const val ACTION_HISTORY = "widget_history"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update each widget instance
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            ACTION_CAMERA -> {
                // Launch app with camera action
                launchAppWithAction(context, "camera")
            }
            ACTION_GALLERY -> {
                // Launch app with gallery action
                launchAppWithAction(context, "gallery")
            }
            ACTION_HISTORY -> {
                // Launch app with history action
                launchAppWithAction(context, "history")
            }
        }
    }

    private fun launchAppWithAction(context: Context, action: String) {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("widget_action", action)
        }
        context.startActivity(intent)
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Create RemoteViews for the widget layout
        val views = RemoteViews(context.packageName, R.layout.lensify_widget_layout)

        // Set up click listeners for buttons
        setupButtonClickListeners(context, views)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun setupButtonClickListeners(context: Context, views: RemoteViews) {
        // Camera button intent
        val cameraIntent = Intent(context, LensifyWidgetProvider::class.java).apply {
            action = ACTION_CAMERA
        }
        val cameraPendingIntent = PendingIntent.getBroadcast(
            context, 
            0, 
            cameraIntent, 
            getPendingIntentFlags()
        )
        views.setOnClickPendingIntent(R.id.widget_camera_button, cameraPendingIntent)

        // Gallery button intent
        val galleryIntent = Intent(context, LensifyWidgetProvider::class.java).apply {
            action = ACTION_GALLERY
        }
        val galleryPendingIntent = PendingIntent.getBroadcast(
            context, 
            1, 
            galleryIntent, 
            getPendingIntentFlags()
        )
        views.setOnClickPendingIntent(R.id.widget_gallery_button, galleryPendingIntent)

        // History button intent
        val historyIntent = Intent(context, LensifyWidgetProvider::class.java).apply {
            action = ACTION_HISTORY
        }
        val historyPendingIntent = PendingIntent.getBroadcast(
            context, 
            2, 
            historyIntent, 
            getPendingIntentFlags()
        )
        views.setOnClickPendingIntent(R.id.widget_history_button, historyPendingIntent)
    }

    private fun getPendingIntentFlags(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
    }

    override fun onEnabled(context: Context) {
        // Called when the first widget is added
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        // Called when the last widget is removed
        super.onDisabled(context)
    }
} 