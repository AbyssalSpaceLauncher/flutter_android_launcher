package com.example.flutter_android_launcher

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import android.os.UserHandle
import android.os.UserManager
import android.app.role.RoleManager
import android.content.pm.LauncherApps
import android.content.pm.ApplicationInfo
import org.json.JSONArray
import org.json.JSONObject
import android.content.ActivityNotFoundException
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.VectorDrawable
import android.graphics.Bitmap
import android.graphics.Canvas
import android.content.BroadcastReceiver
import android.util.Base64
import java.io.ByteArrayOutputStream

/** FlutterAndroidLauncherPlugin */
class FlutterAndroidLauncherPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel : MethodChannel
  private lateinit var userManager: UserManager
  private lateinit var context: Context
  private lateinit var activity: Activity

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_android_launcher")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext

    val filter = IntentFilter().apply {
      addAction(Intent.ACTION_PROFILE_AVAILABLE)
      addAction(Intent.ACTION_PROFILE_UNAVAILABLE)
    }
    context.registerReceiver(profileReceiver, filter)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "getInstalledApps" -> {
        val installedApps = getInstalledApps()
        if (installedApps.isNotEmpty()) {
          result.success(installedApps)
        } else {
          result.error("UNAVAILABLE", "Installed apps not available.", null)
        }
      }
      "launchApp" -> {
        val packageName = call.argument<String>("packageName")
        val profile = call.argument<String>("profile")
        if (packageName != null && profile != null) {
          launchApp(packageName, profile)
          result.success(null)
        } else {
          result.error("INVALID_ARGUMENT", "Package name and profile are required.", null)
        }
      }
      "getLauncherUserInfo" -> {
        val launcherUserInfo = getLauncherUserInfo()
        if (launcherUserInfo != null) {
          result.success(launcherUserInfo)
        } else {
          result.error("UNAVAILABLE", "Launcher user info not available.", null)
        }
      }
      "isQuietModeEnabled" -> {
        val profile = call.argument<String>("profile")
        if (profile != null) {
          val isQuietModeEnabled = isQuietModeEnabled(profile)
          result.success(isQuietModeEnabled)
        } else {
          result.error("INVALID_ARGUMENT", "Profile is required.", null)
        }
      }
      "requestQuietModeEnabled" -> {
        val enableQuietMode = call.argument<Boolean>("enableQuietMode") ?: true
        val profile = call.argument<String>("profile")
        if (profile != null) {
          val success = requestQuietModeEnabled(enableQuietMode, profile)
          result.success(success)
        } else {
          result.error("INVALID_ARGUMENT", "Profile is required.", null)
        }
      }
      else -> result.notImplemented()
    }
  }

  private val profileReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      val userHandle: UserHandle? = intent.getParcelableExtra(Intent.EXTRA_USER)
      if (userHandle != null) {
        val isQuietModeEnabled = userManager.isQuietModeEnabled(userHandle)
        channel.invokeMethod("updateQuietModeStatus", isQuietModeEnabled)
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    context.unregisterReceiver(profileReceiver)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    userManager = activity.getSystemService(Context.USER_SERVICE) as UserManager
  }

  override fun onDetachedFromActivity() {
    // Not yet implemented
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    onAttachedToActivity(binding)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity()
  }

  private fun getInstalledApps(): String {
    val installedApps = getInstalledAppsList()
    val jsonArray = JSONArray()

    for ((profile, appInfo) in installedApps) {
      val pm = context.packageManager
      val appName = pm.getApplicationLabel(appInfo).toString()
      val packageName = appInfo.packageName
      val iconBase64 = getIconBase64(appInfo)

      val jsonObject = JSONObject()
      jsonObject.put("appName", appName)
      jsonObject.put("packageName", packageName)
      jsonObject.put("profile", profile.toString())
      jsonObject.put("iconBase64", iconBase64)
      jsonArray.put(jsonObject)
    }

    return jsonArray.toString()
  }

  private fun getIconBase64(appInfo: ApplicationInfo): String {
    val pm = context.packageManager
    val icon = pm.getApplicationIcon(appInfo)
    val bitmap = try {
      when (icon) {
        is BitmapDrawable -> icon.bitmap
        is AdaptiveIconDrawable, is VectorDrawable -> {
          val bitmap = Bitmap.createBitmap(icon.intrinsicWidth, icon.intrinsicHeight, Bitmap.Config.ARGB_8888)
          val canvas = Canvas(bitmap)
          icon.setBounds(0, 0, canvas.width, canvas.height)
          icon.draw(canvas)
          bitmap
        }
        else -> throw IllegalArgumentException("Unsupported drawable type")
      }
    } catch (e: IllegalArgumentException) {
      // Return a placeholder image in case of unsupported drawable type
      Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
    }
    val outputStream = ByteArrayOutputStream()
    bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
    return Base64.encodeToString(outputStream.toByteArray(), Base64.NO_WRAP)
  }

  private fun getInstalledAppsList(): List<Pair<UserHandle, ApplicationInfo>> {
    val result: ArrayList<Pair<UserHandle, ApplicationInfo>> = arrayListOf()
    val userManager = context.getSystemService(Context.USER_SERVICE) as UserManager
    val launcherApps = context.getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps

    for (profile in userManager.userProfiles) {
      for (app in launcherApps.getActivityList(null, profile)) {
        result.add(Pair(profile, app.applicationInfo))
      }
    }

    return result
  }

  private fun launchApp(packageName: String, profile: String) {
    val launcherApps = context.getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
    val userManager = context.getSystemService(Context.USER_SERVICE) as UserManager
    var userHandle = userManager.userProfiles.find { it.toString() == profile }
    
    if (userHandle != null) {
      val appInfo = launcherApps.getApplicationInfo(packageName, 0, userHandle)
      val componentName = launcherApps.getActivityList(packageName, userHandle).firstOrNull()?.componentName
      if (componentName != null) {
        try {
          launcherApps.startMainActivity(componentName, userHandle, null, null)
        } catch (e: SecurityException) {
          print("Could not launch app: ${e.message}")
        } catch (e: ActivityNotFoundException) {
          print("Could not launch app: ${e.message}")
        } catch (e: Exception) {
          print("An unexpected error occurred: ${e.message}")
        }
      } else {
        print("Component name is null")
      }
      if (!launcherApps.isActivityEnabled(componentName, userHandle)) {
        print("Activity is not enabled for the user")
        return
      }
    } else {
      print("User handle is null")
    }
  }

  private fun getLauncherUserInfo(): String? {
    if (VERSION.SDK_INT >= 35) {
      val roleManager = context.getSystemService(Context.ROLE_SERVICE) as RoleManager
      val launcherApps = context.getSystemService(Context.LAUNCHER_APPS_SERVICE) as LauncherApps
      if (roleManager.isRoleHeld(RoleManager.ROLE_HOME)) {
        val userManager = context.getSystemService(Context.USER_SERVICE) as UserManager
        val users = userManager.userProfiles
        if (users != null && users.isNotEmpty()) {
          val jsonArray = JSONArray()
          for (user in users) {
            val userInfo = launcherApps.getLauncherUserInfo(user)
            if (userInfo != null) {
              val userType = userInfo.userType
              val jsonObject = JSONObject()
              jsonObject.put("userProfile", user.toString())
              jsonObject.put("userType", userType)
              jsonArray.put(jsonObject)
            }
          }
          return jsonArray.toString()
        }
      }
    }
    return null
  }

  private fun isQuietModeEnabled(profile: String): Boolean {
    val userManager = context.getSystemService(Context.USER_SERVICE) as UserManager
    for (userHandle in userManager.userProfiles) {
      if (userManager.isQuietModeEnabled(userHandle)) {
        return true
      }
    }
    return false
  }

  private fun requestQuietModeEnabled(enableQuietMode: Boolean, profile: String): Boolean {
    val userManager = context.getSystemService(Context.USER_SERVICE) as UserManager
    val userHandle = userManager.userProfiles.find { it.toString() == profile }
    return userHandle?.let { userManager.requestQuietModeEnabled(enableQuietMode, it) } ?: false
  }
}
