package com.bjbybbs.prescore_flutter

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.opencv.android.OpenCVLoader
import org.opencv.core.Mat
import org.opencv.core.MatOfByte
import org.opencv.core.MatOfPoint
import org.opencv.core.Scalar
import org.opencv.core.Size
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc
import kotlin.math.absoluteValue

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.bjbybbs.prescore_flutter/opencv"
    private var opencvLoaded = false
    private var opencvInvoker = OpenCVInvoker()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (!opencvLoaded) {
                opencvLoaded = OpenCVLoader.initDebug()
                if (!opencvLoaded) {
                    println("OpenCV failed to load")
                }
            }

            when (call.method) {
                "cvtColor" -> {
                    opencvInvoker.cvtColor(call.argument<ByteArray>("src")!!, call.argument<Int>("code")!!).let {
                        result.success(it)
                    }
                }
                "dilate" -> {
                    opencvInvoker.dilate(call.argument<ByteArray>("src")!!).let {
                        result.success(it)
                    }
                }
                "Canny" -> {
                    opencvInvoker.canny(call.argument<ByteArray>("src")!!).let {
                        result.success(it)
                    }
                }
                "findContours" -> {
                    opencvInvoker.findContours(call.argument<ByteArray>("src")!!).let {
                        result.success(it)
                    }
                }
                "edgeDetect" -> {
                    val src = call.argument<ByteArray>("src")!!
                    val code = call.argument<Int>("code")!!
                    val t1 = call.argument<Double>("t1")!!
                    val t2 = call.argument<Double>("t2")!!
                    val blurSize = call.argument<Double>("blurSize")!!
                    val dilateSize = call.argument<Double>("dilateSize")!!

                    val srcMat = Imgcodecs.imdecode(MatOfByte(*src), Imgcodecs.IMREAD_UNCHANGED)

                    // Transform RGB to GRAYSCALE
                    var cvtMat = Mat()
                    if (srcMat.channels() == 3) {
                        Imgproc.cvtColor(srcMat, cvtMat, code)
                    } else {
                        cvtMat = srcMat
                    }

                    // Gaussian Blur
                    val gbMat = Mat()
                    Imgproc.GaussianBlur(cvtMat, gbMat, Size(blurSize, blurSize), 0.0, 0.0)

                    // Dilate image
                    val dilateMat = Mat()
                    val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(dilateSize, dilateSize))
                    Imgproc.dilate(gbMat, dilateMat, kernel)

                    // Canny edge detect
                    val cannyMat = Mat()
                    Imgproc.Canny(dilateMat, cannyMat, t1, t2)


                    // Find contours
                    val contours = MutableList(0) { MatOfPoint() }
                    val hierarchy = Mat()
                    Imgproc.findContours(cannyMat, contours, hierarchy, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)

                    // Find the max contour
                    var maxArea = 0.0
                    var index = 0
                    contours.forEach { contour ->
                        val area: Double = Imgproc.contourArea(contour).absoluteValue
                        if (area > maxArea) {
                            maxArea = area
                            index = contours.indexOf(contour)
                        }
                    }

                    Imgproc.drawContours(cannyMat, contours.subList(index, index + 1), -1, Scalar.all(255.0), -1)

                    // Generate blank image
                    // val blankMat = Mat.zeros(srcMat.size(), srcMat.type())
                    // Imgproc.rectangle(cannyMat, rect, Scalar.all(255.0), -1)

                    // Output
                    val outMat = MatOfByte()
                    Imgcodecs.imencode(".png", cannyMat, outMat)

                    result.success(outMat.toArray())
                }
                else -> result.notImplemented()
            }
        }
    }

}
