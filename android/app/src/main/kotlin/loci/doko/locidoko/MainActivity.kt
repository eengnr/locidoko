package loci.doko.locidoko

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}

// Use the code below as alternative to the official Flutter geolocator dependency to not use any GMS dependencies
// I'll leave this commented out for documentation purposes
/*import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle

data class LocationData(val latitude: Double, val longitude: Double)

class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "loci.doko.locidoko/getlocation")
        channel.setMethodCallHandler { call, result ->
            if (call.method == "getLocation") {
                getLocation(result)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun getLocation(result: MethodChannel.Result) {
        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val locationListener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                val locationData = LocationData(location.latitude, location.longitude)
                result.success(mapOf("latitude" to locationData.latitude, "longitude" to locationData.longitude))
                locationManager.removeUpdates(this)
            }

            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}

            override fun onProviderEnabled(provider: String) {}

            override fun onProviderDisabled(provider: String) {
                result.error("UNAVAILABLE", "Location provider disabled", null)
                locationManager.removeUpdates(this)
            }
        }

        try {
            locationManager.requestLocationUpdates(LocationManager.GPS_PROVIDER, 0L, 0f, locationListener)
            locationManager.requestLocationUpdates(LocationManager.NETWORK_PROVIDER, 0L, 0f, locationListener)
        } catch (e: SecurityException) {
            result.error("PERMISSION_DENIED", "Location permission denied", null)
        }
    }
}
*/