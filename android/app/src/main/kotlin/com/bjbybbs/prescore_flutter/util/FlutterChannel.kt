package com.bjbybbs.prescore_flutter.util

import android.content.Context
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

class FlutterChannel {
    private lateinit var messenger: BinaryMessenger
    private lateinit var channel: MethodChannel
    private lateinit var flutterEngine: FlutterEngine
    private val engineId = "ServiceEngine"

    fun engineInit(context: Context) {
        flutterEngine = FlutterEngine(context)
        //flutterEngine?.navigationChannel?.setInitialRoute("/")
        flutterEngine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "serviceEntry"))
        FlutterEngineCache
            .getInstance()
            .put(engineId, flutterEngine)
        messenger = flutterEngine.dartExecutor.binaryMessenger
        channel = MethodChannel(messenger, "PrescoreService")
    }
    fun releaseFlutterEngine() {
        flutterEngine?.let { engine ->
            FlutterEngineCache.getInstance().remove(engineId)
            engine.destroy()
        }
    }
    fun setMethodCallHandler(method: ((callMethod: String, callArguments: Any?) -> Any?)) {
        channel.setMethodCallHandler { call, result ->
            //TODO:
            method(call.method, call.arguments)
            result.success("")
        }
    }
    fun invoke(
        methodName: String,
        arguments: Any?,
        onSuccess: (result: Any?) -> Any? = {},
        onError: (errorCode: String, errorMessage: String?, errorDetails: Any?) -> Any? = fun (_: String, _: String?, _: Any?) {}
    ) {
        channel.invokeMethod(methodName, arguments, object : MethodChannel.Result {
            override fun success(result: Any?) {
                onSuccess.invoke(result)
            }
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                println("Error: $errorMessage")
                onError.invoke(errorCode, errorMessage, errorDetails)
            }
            override fun notImplemented() {
                println("Method not implemented")
            }
        })
    }
}