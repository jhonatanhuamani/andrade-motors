package com.example.andrade_motors

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity(), SensorEventListener, EventChannel.StreamHandler {
    private val sensores = mapOf(
        Sensor.TYPE_ACCELEROMETER to "acelerometro",
        Sensor.TYPE_GYROSCOPE to "giroscopio",
        Sensor.TYPE_PROXIMITY to "proximidad",
        Sensor.TYPE_LIGHT to "luz"
    )
    private val ultimaLectura = mutableMapOf<Int, Long>()
    private lateinit var manager: SensorManager
    private var canal: EventChannel? = null
    private var eventos: EventChannel.EventSink? = null
    private var enPrimerPlano = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        manager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        canal = EventChannel(flutterEngine.dartExecutor.binaryMessenger, "andrade_motors/sensores")
        canal?.setStreamHandler(this)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        onCancel(null)
        canal?.setStreamHandler(null)
        canal = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onResume() {
        super.onResume()
        enPrimerPlano = true
        registrar()
    }

    override fun onPause() {
        enPrimerPlano = false
        detener()
        super.onPause()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        detener()
        eventos = events
        registrar()
    }

    override fun onCancel(arguments: Any?) {
        eventos = null
        detener()
    }

    private fun registrar() {
        val salida = eventos ?: return
        if (!enPrimerPlano) return
        val disponibles = sensores.mapNotNull { (tipo, nombre) ->
            val sensor = manager.getDefaultSensor(tipo) ?: return@mapNotNull null
            if (manager.registerListener(this, sensor, SensorManager.SENSOR_DELAY_UI)) nombre
            else null
        }
        salida.success(mapOf("disponibles" to disponibles))
    }

    private fun detener() {
        if (::manager.isInitialized) manager.unregisterListener(this)
        ultimaLectura.clear()
    }

    override fun onSensorChanged(event: SensorEvent) {
        val tipo = event.sensor.type
        val nombre = sensores[tipo] ?: return
        val anterior = ultimaLectura[tipo]
        if (anterior != null && event.timestamp - anterior < 100_000_000L) return
        ultimaLectura[tipo] = event.timestamp
        eventos?.success(
            mapOf(
                "sensor" to nombre,
                "valores" to event.values.map { it.toDouble() },
                "rango" to event.sensor.maximumRange.toDouble()
            )
        )
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
}
