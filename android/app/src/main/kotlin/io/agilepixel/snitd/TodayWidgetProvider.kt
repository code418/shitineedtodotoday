package io.agilepixel.snitd

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Paint
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * The "Today" home-screen widget.
 *
 * Draws the snapshot the Flutter app publishes (lib/features/home_widget):
 * today's chores, open ones first, with pre-rendered labels in the user's
 * chosen string set. Each open chore's tick completes it in the background
 * (Dart's onHomeWidgetTap, via home_widget) without opening the app; a tap
 * anywhere else opens the app.
 *
 * A snapshot from an earlier day is never shown as today's list — the widget
 * asks to open the app instead (updatePeriodMillis re-draws it after
 * midnight).
 */
class TodayWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val snapshot =
        widgetData.getString(SNAPSHOT_KEY, null)?.let {
          try {
            JSONObject(it)
          } catch (_: Exception) {
            null
          }
        }
    for (id in appWidgetIds) {
      appWidgetManager.updateAppWidget(id, render(context, snapshot))
    }
  }

  private fun render(context: Context, snapshot: JSONObject?): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.today_widget)
    views.setOnClickPendingIntent(
        R.id.widget_root,
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
    )
    views.removeAllViews(R.id.widget_rows)
    views.setViewVisibility(R.id.widget_more, View.GONE)

    val labels = snapshot?.optJSONObject("labels")
    views.setTextViewText(
        R.id.widget_title,
        labels?.optString("title")?.takeIf { it.isNotEmpty() }
            ?: context.getString(R.string.today_widget_label),
    )
    views.setTextViewText(R.id.widget_progress, "")

    // Never synced yet: the layout's default message asks to open the app.
    if (snapshot == null || labels == null) {
      views.setViewVisibility(R.id.widget_message, View.VISIBLE)
      return views
    }
    if (snapshot.optString("day") != today()) {
      return message(views, labels.optString("stale"))
    }

    val items = snapshot.optJSONArray("items")
    val left = snapshot.optInt("left")
    val total = snapshot.optInt("total")
    if (items == null || total == 0) {
      return message(views, labels.optString("empty"))
    }

    for (i in 0 until items.length()) {
      views.addView(R.id.widget_rows, row(context, items.getJSONObject(i), labels))
    }
    val hidden = total - items.length()
    if (hidden > 0) {
      views.setViewVisibility(R.id.widget_more, View.VISIBLE)
      views.setTextViewText(
          R.id.widget_more,
          labels.optString("more").replace("{n}", hidden.toString()),
      )
    }
    if (left == 0) {
      // Everything's done: say so under the ticked-off rows.
      return message(views, labels.optString("allDone"))
    }
    views.setTextViewText(
        R.id.widget_progress,
        labels
            .optString("progress")
            .replace("{left}", left.toString())
            .replace("{total}", total.toString()),
    )
    views.setViewVisibility(R.id.widget_message, View.GONE)
    return views
  }

  private fun message(views: RemoteViews, text: String): RemoteViews {
    views.setTextViewText(R.id.widget_message, text)
    views.setViewVisibility(R.id.widget_message, View.VISIBLE)
    return views
  }

  private fun row(context: Context, item: JSONObject, labels: JSONObject): RemoteViews {
    val row = RemoteViews(context.packageName, R.layout.today_widget_row)
    val title = item.optString("title")
    row.setTextViewText(R.id.row_title, title)
    row.setTextViewText(R.id.row_minutes, "~${item.optInt("minutes")}m")

    if (item.optBoolean("done")) {
      row.setImageViewResource(R.id.row_tick, R.drawable.ic_widget_tick_done)
      row.setInt(
          R.id.row_title,
          "setPaintFlags",
          Paint.STRIKE_THRU_TEXT_FLAG or Paint.ANTI_ALIAS_FLAG,
      )
      row.setTextColor(R.id.row_title, context.getColor(R.color.widget_text_muted))
      row.setContentDescription(R.id.row_tick, "$title, ${labels.optString("done")}")
    } else {
      // A distinct URI per chore, so each tick is its own PendingIntent.
      val tick =
          Uri.parse(TICK_URI)
              .buildUpon()
              .appendQueryParameter("occ", item.optString("id"))
              .build()
      row.setOnClickPendingIntent(
          R.id.row_tick,
          HomeWidgetBackgroundIntent.getBroadcast(context, tick),
      )
      row.setContentDescription(R.id.row_tick, "${labels.optString("tick")} $title")
    }
    return row
  }

  /** Today's local date, in the snapshot's `yyyy-MM-dd` form. */
  private fun today(): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())

  private companion object {
    /** Must match kWidgetSnapshotKey in home_widget_bridge.dart. */
    const val SNAPSHOT_KEY = "today_snapshot"

    /** Parsed by onHomeWidgetTap in widget_background.dart. */
    const val TICK_URI = "sintdt://complete"
  }
}
