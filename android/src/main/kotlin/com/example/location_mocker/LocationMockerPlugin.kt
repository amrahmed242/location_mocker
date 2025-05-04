package com.example.location_mocker

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationManager
import android.os.*
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.xmlpull.v1.XmlPullParser
import org.xmlpull.v1.XmlPullParserFactory
import java.io.StringReader
import java.text.SimpleDateFormat
import java.util.*
import kotlin.collections.ArrayList
import kotlin.math.roundToLong
import android.util.Log
import io.flutter.plugin.common.EventChannel

class LocationMockerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var locationManager: LocationManager? = null
  private var mockLocationProvider: String = LocationManager.GPS_PROVIDER
  private var gpxPoints = ArrayList<GpxPoint>()
  private var currentPointIndex = 0
  private var playbackSpeed = 1.0
  private var mockerHandler: Handler? = null
  private var isMocking = false
  
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null
  
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
  channel = MethodChannel(flutterPluginBinding.binaryMessenger, "location_mocker")
  channel.setMethodCallHandler(this)
  
  eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "location_mocker_events")
  eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
      eventSink = events
    }

    override fun onCancel(arguments: Any?) {
      eventSink = null
    }
  })
  
  context = flutterPluginBinding.applicationContext
  locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager

  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "initialize" -> {
        try {
          result.success(true)
        } catch (e: Exception) {
          result.error("INIT_ERROR", e.message, null)
        }
      }
      "isMockLocationEnabled" -> {
        try {
          val isEnabled = isMockLocationEnabled()
          result.success(isEnabled)
        } catch (e: Exception) {
          result.error("CHECK_MOCK_ERROR", e.message, null)
        }
      }
      "startMockingWithGpx" -> {
        try {
          val gpxData = call.argument<String>("gpxData") ?: ""
          playbackSpeed = call.argument<Double>("playbackSpeed") ?: 1.0
          
          if (!isMockLocationEnabled()) {
            result.error("MOCK_NOT_ENABLED", "Mock location is not enabled in developer options", null)
            return
          }
          
          parseGpxData(gpxData)
          startMocking()
          result.success(true)
        } catch (e: Exception) {
          result.error("START_MOCK_ERROR", e.message, null)
        }
      }
      "updatePlaybackSpeed" -> {
        try {
          playbackSpeed = call.argument<Double>("playbackSpeed") ?: 1.0
          result.success(true)
        } catch (e: Exception) {
          result.error("UPDATE_SPEED_ERROR", e.message, null)
        }
      }
      "stopMocking" -> {
        try {
          stopMocking()
          result.success(true)
        } catch (e: Exception) {
          result.error("STOP_MOCK_ERROR", e.message, null)
        }
      }
      "openMockLocationSettings" -> {
        openMockLocationSettings()
        result.success(true)
      }
      "pauseMocking" -> {
      try {
        if (isMocking) {
          // Pause by setting playback speed to 0
          playbackSpeed = 0.0
          result.success(true)
        } else {
          result.success(false)
        }
      } catch (e: Exception) {
        result.error("PAUSE_ERROR", e.message, null)
      }
    }

    "resumeMocking" -> {
      try {
        if (isMocking) {
          // Resume with previous or default speed
          playbackSpeed = call.argument<Double>("playbackSpeed") ?: 1.0
          result.success(true)
        } else {
          result.success(false)
        }
      } catch (e: Exception) {
        result.error("RESUME_ERROR", e.message, null)
      }
    }
      else -> result.notImplemented()
    }
  }

  private fun isMockLocationEnabled(): Boolean {
    try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // For Android M and above, we need to check if app has been granted mock location permission
            val appContext = context.applicationContext
            var isAllowed = false
            
            try {
                // The app is the mock location app if it has location permissions 
                // and if mock location is enabled in developer options
                val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
                
                // Try to add and immediately remove a test provider
                val providerName = "test_provider_${System.currentTimeMillis()}"
                
                locationManager.addTestProvider(
                    providerName,
                    false, false, false, false, false, false, false,
                    android.location.Criteria.POWER_LOW, android.location.Criteria.ACCURACY_FINE
                )
                
                locationManager.removeTestProvider(providerName)
                isAllowed = true
            } catch (e: SecurityException) {
                // If we get a security exception, the app is not set as the mock location app
                Log.d("LocationMocker", "Not allowed to mock locations: ${e.message}")
                isAllowed = false
            } catch (e: Exception) {
                Log.e("LocationMocker", "Error checking mock location permission: ${e.message}")
            }
            
            return isAllowed
        } else {
            // For older versions, check if mock location is enabled in dev settings
            return Settings.Secure.getInt(
                context.contentResolver,
                Settings.Secure.ALLOW_MOCK_LOCATION
            ) == 1
        }
    } catch (e: Exception) {
        Log.e("LocationMocker", "Error in isMockLocationEnabled: ${e.message}")
        e.printStackTrace()
        return false
    }
}

  private fun parseGpxData(gpxData: String) {
    gpxPoints.clear()
    
    try {
      val factory = XmlPullParserFactory.newInstance()
      factory.isNamespaceAware = true
      val parser = factory.newPullParser()
      parser.setInput(StringReader(gpxData))
      
      var eventType = parser.eventType
      var currentTag: String? = null
      var lat: Double? = null
      var lon: Double? = null
      var ele: Double? = null
      var time: String? = null
      var bearing: Double? = null
      while (eventType != XmlPullParser.END_DOCUMENT) {
        when (eventType) {
          XmlPullParser.START_TAG -> {
            currentTag = parser.name
            
            if (currentTag == "trkpt") {
              lat = parser.getAttributeValue(null, "lat")?.toDoubleOrNull()
              lon = parser.getAttributeValue(null, "lon")?.toDoubleOrNull()
              ele = null
              time = null
              bearing = parser.getAttributeValue(null, "bearing")?.toDoubleOrNull()
            }
          }
          XmlPullParser.TEXT -> {
            val text = parser.text?.trim()
            if (!text.isNullOrEmpty()) {
              when (currentTag) {
                "ele" -> ele = text.toDoubleOrNull()
                "time" -> time = text
              }
            }
          }
          XmlPullParser.END_TAG -> {
            if (parser.name == "trkpt" && lat != null && lon != null) {
              val point = GpxPoint(lat, lon, ele, time, bearing)
              gpxPoints.add(point)
            }
            currentTag = null
          }
        }
        eventType = parser.next()
      }
    } catch (e: Exception) {
      throw RuntimeException("Failed to parse GPX data: ${e.message}")
    }
    
    if (gpxPoints.isEmpty()) {
      throw RuntimeException("No valid track points found in GPX data")
    }
  }

  private fun startMocking() {
    if (gpxPoints.isEmpty()) return
    
    try {
        // First try to remove any existing test provider with that name
        // (in case it wasn't properly cleaned up on a previous run)
        try {
            locationManager!!.removeTestProvider(mockLocationProvider)
        } catch (e: Exception) {
            // Ignore errors here - the provider might not exist yet
        }
        
        // Create the test provider with all necessary parameters
        locationManager!!.addTestProvider(
            mockLocationProvider,  // provider name (GPS_PROVIDER)
            false,  // requiresNetwork
            false,  // requiresSatellite
            false,  // requiresCell
            false,  // hasMonetaryCost
            true,   // supportsAltitude
            true,   // supportsSpeed
            true,   // supportsBearing
            android.location.Criteria.POWER_LOW,
            android.location.Criteria.ACCURACY_FINE
        )
        
        // Enable the provider
        locationManager!!.setTestProviderEnabled(mockLocationProvider, true)
        
        // Reset state
        currentPointIndex = 0
        isMocking = true
        
        // Create handler for sending mock locations
        val handlerThread = HandlerThread("LocationMockerThread")
        handlerThread.start()
        mockerHandler = Handler(handlerThread.looper)
        
        // Schedule the first location update
        scheduleNextLocation()
    } catch (e: SecurityException) {
        throw RuntimeException("Insufficient permissions to mock location: ${e.message}")
    } catch (e: IllegalArgumentException) {
        // If we get "provider is not a test provider", try an alternative approach
        // Some devices might have issues with the standard GPS_PROVIDER
        try {
            // Try using a custom named provider instead
            mockLocationProvider = "mock_gps_provider"
            
            // Create test provider with our custom name
            locationManager!!.addTestProvider(
                mockLocationProvider,
                false, false, false, false, true, true, true,
                android.location.Criteria.POWER_LOW, android.location.Criteria.ACCURACY_FINE
            )
            
            locationManager!!.setTestProviderEnabled(mockLocationProvider, true)
            
            // Reset state
            currentPointIndex = 0
            isMocking = true
            
            // Create handler for sending mock locations
            val handlerThread = HandlerThread("LocationMockerThread")
            handlerThread.start()
            mockerHandler = Handler(handlerThread.looper)
            
            // Schedule the first location update
            scheduleNextLocation()
        } catch (e2: Exception) {
            throw RuntimeException("Failed to create test provider: ${e2.message}")
        }
    } catch (e: Exception) {
        throw RuntimeException("Failed to start location mocking: ${e.message}")
    }
}

  private fun scheduleNextLocation() {
    if (!isMocking || currentPointIndex >= gpxPoints.size) {
      stopMocking()
      return
    }
    
    val currentPoint = gpxPoints[currentPointIndex]
    sendMockLocation(currentPoint)
    
    currentPointIndex++
    
    // If we have more points, schedule the next one
    if (currentPointIndex < gpxPoints.size) {
      val nextPoint = gpxPoints[currentPointIndex]
      val delayMs = calculateDelay(currentPoint, nextPoint)
      mockerHandler?.postDelayed({ scheduleNextLocation() }, delayMs)
    } else {
      // We've reached the end
      stopMocking()
    }
  }
  
private fun calculateDelay(current: GpxPoint, next: GpxPoint): Long {
  // If we have timestamps, use them
  val currentTime = current.time
  val nextTime = next.time
  
  if (currentTime != null && nextTime != null) {
    val diffMs = nextTime.time - currentTime.time
    return (diffMs / playbackSpeed).roundToLong()
  }
  
  // Otherwise, use a default delay (1 second between points)
  return (1000 / playbackSpeed).roundToLong()
}
  
  private fun sendMockLocation(point: GpxPoint) {
    try {
      val location = Location(mockLocationProvider)
      location.latitude = point.latitude
      location.longitude = point.longitude
      location.altitude = point.elevation ?: 0.0
      location.time = System.currentTimeMillis()
      location.elapsedRealtimeNanos = SystemClock.elapsedRealtimeNanos()
      location.accuracy = 3f

      if (point.bearing != null) {
        location.bearing = point.bearing.toFloat()
      }
      
      // Set as mock location for Android O+
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        location.bearingAccuracyDegrees = 0.1f
        location.speedAccuracyMetersPerSecond = 0.01f
        location.verticalAccuracyMeters = 0.1f
      }
      
      // Set mock location flag for Android Jelly Bean MR2+
      try {
        val locationJellyBean = Location::class.java
        val locationSetMethod = locationJellyBean.getMethod("setIsFromMockProvider", Boolean::class.javaPrimitiveType)
        locationSetMethod.invoke(location, true)
      } catch (e: Exception) {
        // Ignore, not all devices have this method
      }

      val eventData = HashMap<String, Any>()
      eventData["latitude"] = point.latitude
      eventData["longitude"] = point.longitude
      if (point.elevation != null) eventData["elevation"] = point.elevation
      val timeValue = point.time
      if (timeValue != null) {
          eventData["time"] = convertDateToIso8601(timeValue)
      }
      if (point.bearing != null) eventData["bearing"] = point.bearing
      
      // Send on main thread
      Handler(Looper.getMainLooper()).post {
        eventSink?.success(eventData)
      }
    
      locationManager!!.setTestProviderLocation(mockLocationProvider, location)
    } catch (e: Exception) {
      // Log error but continue
      e.printStackTrace()
    }
  }
  
  private fun stopMocking() {
    try {
      isMocking = false
      
      // Clean up handler
      mockerHandler?.removeCallbacksAndMessages(null)
      mockerHandler = null
      
      // Disable mock provider
      if (locationManager != null && locationManager!!.getProviders(false).contains(mockLocationProvider)) {
        try {
          locationManager!!.setTestProviderEnabled(mockLocationProvider, false)
          locationManager!!.removeTestProvider(mockLocationProvider)
        } catch (e: Exception) {
          // Ignore errors when removing provider
        }
      }
    } catch (e: Exception) {
      e.printStackTrace()
    }
  }
  
  data class GpxPoint(
    val latitude: Double,
    val longitude: Double,
    val elevation: Double?,
    val timeString: String?,
    val bearing: Double?
  ) {
    val time: Date?
      get() {
        if (timeString == null) return null
        return try {
          val formats = arrayOf(
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ssXXX",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
          )
          
          for (format in formats) {
            try {
              val sdf = SimpleDateFormat(format, Locale.US)
              sdf.timeZone = TimeZone.getTimeZone("UTC")
              return sdf.parse(timeString)
            } catch (e: Exception) {
              // Try next format
            }
          }
          null
        } catch (e: Exception) {
          null
        }
      }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    stopMocking()
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  private fun openMockLocationSettings() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        try {
            // Open developer options
            val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        } catch (e: Exception) {
            // If developer options not available, open main settings
            try {
                val intent = Intent(Settings.ACTION_SETTINGS)
                intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                context.startActivity(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    } else {
        // For older Android versions
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
private fun convertDateToIso8601(date: Date): String {
  val format = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US)
  format.timeZone = TimeZone.getTimeZone("UTC")
  return format.format(date)
}
}