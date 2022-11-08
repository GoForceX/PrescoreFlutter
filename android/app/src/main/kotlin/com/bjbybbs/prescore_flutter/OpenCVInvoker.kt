package com.bjbybbs.prescore_flutter

import org.opencv.core.Mat
import org.opencv.core.MatOfByte
import org.opencv.core.MatOfPoint
import org.opencv.core.Size
import org.opencv.imgcodecs.Imgcodecs
import org.opencv.imgproc.Imgproc

class OpenCVInvoker {
    fun cvtColor(src: ByteArray, code: Int): ByteArray {
        val srcMat = Imgcodecs.imdecode(MatOfByte(*src), Imgcodecs.IMREAD_UNCHANGED)

        val interMat = Mat()
        val outMat = MatOfByte()
        Imgproc.cvtColor(srcMat, interMat, code)
        Imgcodecs.imencode(".png", interMat, outMat)

        return outMat.toArray()
    }

    fun dilate(src: ByteArray): ByteArray {
        val srcMat = Imgcodecs.imdecode(MatOfByte(*src), Imgcodecs.IMREAD_UNCHANGED)

        val interMat = Mat()
        val outMat = MatOfByte()
        val kernel = Imgproc.getStructuringElement(Imgproc.MORPH_RECT, Size(3.0, 3.0))

        Imgproc.dilate(srcMat, interMat, kernel)
        Imgcodecs.imencode(".png", interMat, outMat)

        return outMat.toArray()
    }

    fun gaussianBlur(src: ByteArray): ByteArray {
        val srcMat = Imgcodecs.imdecode(MatOfByte(*src), Imgcodecs.IMREAD_UNCHANGED)

        val interMat = Mat()
        val outMat = MatOfByte()

        Imgproc.GaussianBlur(srcMat, interMat, Size(3.0, 3.0), 0.0, 0.0)
        Imgcodecs.imencode(".png", interMat, outMat)

        return outMat.toArray()
    }

    fun canny(src: ByteArray): ByteArray {
        val srcMat = Imgcodecs.imdecode(MatOfByte(*src), Imgcodecs.IMREAD_UNCHANGED)

        val interMat = Mat()
        val outMat = MatOfByte()
        Imgproc.Canny(srcMat, interMat, 30.0, 120.0)
        Imgcodecs.imencode(".png", interMat, outMat)

        return outMat.toArray()
    }

    fun findContours(src: ByteArray): List<MatOfPoint> {
        val srcMat = Imgcodecs.imdecode(MatOfByte(*src), Imgcodecs.IMREAD_UNCHANGED)
        val contours = MutableList(0) { MatOfPoint() }
        val hierarchy = Mat()
        Imgproc.findContours(srcMat, contours, hierarchy, Imgproc.RETR_EXTERNAL, Imgproc.CHAIN_APPROX_SIMPLE)

        return contours.toList()
    }
}
