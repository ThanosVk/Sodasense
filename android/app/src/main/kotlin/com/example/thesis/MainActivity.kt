package com.example.thesis

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    private val press_channel = "pressure_sensor"//Channel for communicating with flutter pressure sensor
    private val prox_channel = "proximity_channel"//Channel for communicating with flutter proximity sensor
    private val acc_channel = "accelerometer_channel"//Channel for communicating with flutter accelerometer sensor
    private val gyro_channel = "gyroscope_channel"//Channel for communicating with flutter gyroscope sensor
    private val magn_channel = "magnetometer_channel"//Channel for communicating with flutter magnetometer sensor
    private val pressure_channel = "pressure_channel" //Pressure event channel for communicating with flutter sensor

    private var presschannel:MethodChannel? = null
    private var proxchannel:MethodChannel? = null
    private var accchannel:MethodChannel? = null
    private var gyrochannel:MethodChannel? = null
    private var magnchannel:MethodChannel? = null
    private lateinit var sensorManager: SensorManager
    private var pressureChannel: EventChannel? = null
    private var pressureStreamHandler:StreamHandler? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        //Setup Channels
        setupChannels(this,flutterEngine.dartExecutor.binaryMessenger)

    }

    override fun onDestroy() {
        teardownChannels()
        super.onDestroy()
    }

    private fun setupChannels(context: Context, messenger: BinaryMessenger){
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager

        //Channel for pressure
        presschannel = MethodChannel(messenger, press_channel)
        presschannel!!.setMethodCallHandler{
            call,result ->
            if (call.method == "isSensorAvailable") {
                result.success(sensorManager!!.getSensorList(Sensor.TYPE_PRESSURE).isNotEmpty())
            } else {
                result.notImplemented()
            }
        }

        //Channel for proximity
        proxchannel = MethodChannel(messenger, prox_channel)
        proxchannel!!.setMethodCallHandler{
            call,result ->
            if (call.method == "isSensorAvailable") {
                result.success(sensorManager!!.getSensorList(Sensor.TYPE_PROXIMITY).isNotEmpty())
            } else {
                result.notImplemented()
            }
        }

        //Channel for accelerometer
        accchannel = MethodChannel(messenger, acc_channel)
        accchannel!!.setMethodCallHandler{
            call,result ->
            if (call.method == "isSensorAvailable") {
                result.success(sensorManager!!.getSensorList(Sensor.TYPE_ACCELEROMETER).isNotEmpty())
            } else {
                result.notImplemented()
            }
        }

        //Channel for gyroscope
        gyrochannel = MethodChannel(messenger, gyro_channel)
        gyrochannel!!.setMethodCallHandler{
            call,result ->
            if (call.method == "isSensorAvailable") {
                result.success(sensorManager!!.getSensorList(Sensor.TYPE_GYROSCOPE).isNotEmpty())
            } else {
                result.notImplemented()
            }
        }

        //Channel for magnetometer
        magnchannel = MethodChannel(messenger, magn_channel)
        magnchannel!!.setMethodCallHandler{
            call,result ->
            if (call.method == "isSensorAvailable") {
                result.success(sensorManager!!.getSensorList(Sensor.TYPE_MAGNETIC_FIELD).isNotEmpty())
            } else {
                result.notImplemented()
            }
        }

        pressureChannel = EventChannel(messenger, pressure_channel)
        pressureStreamHandler = StreamHandler(sensorManager!!, Sensor.TYPE_PRESSURE)
        pressureChannel!!.setStreamHandler(pressureStreamHandler)
    }

    private fun teardownChannels(){
        pressureChannel!!.setStreamHandler(null)
    }

}
