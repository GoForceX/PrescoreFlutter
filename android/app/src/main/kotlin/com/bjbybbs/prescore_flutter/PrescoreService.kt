package com.bjbybbs.prescore_flutter

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import com.bjbybbs.prescore_flutter.util.FlutterChannel
import com.bjbybbs.prescore_flutter.util.WearEngine
import com.huawei.wearengine.p2p.Message
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File
import java.lang.Thread.sleep

@SuppressLint("ServiceCast")
class PrescoreService : Service() {
    private val tag = "PerscoreService"
    private var notificationManager: NotificationManager? = null
    private var notification: Notification? = null
    private var notificationChannel: NotificationChannel? = null
    private val foregroundServiceChannelID = "10"
    private val foregroundServiceChannelName = "前台服务通知"
    private val examUpdateChannelID = "11"
    private val examUpdateChannelName = "考试更新通知"
    private val foregroundID = 1
    private val notificationTitle = "出分啦后台服务"
    private var startCommandRunOnce = false
    private lateinit var sharedPreferences: SharedPreferences
    private lateinit var wakeLock:  PowerManager.WakeLock
    private lateinit var userUtilRequest: FlutterChannel
    private lateinit var wearEngine : WearEngine
    private lateinit var p2pConnectSetup : (_: String) -> Unit
    private var selectedWearDeviceUUID = ""
    private fun setupForeground(text: String = "") {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notificationChannel = NotificationChannel(
                foregroundServiceChannelID,
                foregroundServiceChannelName,
                NotificationManager.IMPORTANCE_DEFAULT
            )
            notificationChannel!!.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
            notificationManager!!.createNotificationChannel(notificationChannel!!)
            notification = Notification.Builder(this, foregroundServiceChannelID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setLargeIcon(BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher))
                .setContentTitle(notificationTitle)
                .setContentText(text)
                .build()
        }
        notification!!.flags = notification!!.flags or Notification.FLAG_NO_CLEAR
        startForeground(foregroundID, notification)
    }
    override fun onCreate() {
        Log.d(tag, "PrescoreService onCreate")
        super.onCreate()
        sharedPreferences = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        setupForeground("暂未登录")
        Log.d(tag, "useWakeLock: ${sharedPreferences.getBoolean("flutter.useWakeLock", false)}")
        if(sharedPreferences.getBoolean("flutter.useWakeLock", false)) {
            wakeLock =
                (getSystemService(Context.POWER_SERVICE) as PowerManager).run {
                    newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Prescore::PrescoreService").apply {
                        acquire()
                    }
                }
        }
        userUtilRequest = FlutterChannel()
        userUtilRequest.engineInit(applicationContext)
        userUtilRequest.setMethodCallHandler(
            fun(method : String, argument : Any?) {
                if(method == "setupForeground") {
                    setupForeground(argument.toString())
                } else if (method == "sendNotification") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        notificationChannel = NotificationChannel(
                            foregroundServiceChannelID,
                            foregroundServiceChannelName,
                            NotificationManager.IMPORTANCE_HIGH
                        )
                        notificationChannel!!.lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                        notificationManager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                        notificationManager!!.createNotificationChannel(notificationChannel!!)
                        notification = Notification.Builder(this, foregroundServiceChannelID)
                            .setSmallIcon(R.mipmap.ic_launcher)
                            .setLargeIcon(BitmapFactory.decodeResource(resources, R.mipmap.ic_launcher))
                            .setContentTitle("出分啦")
                            .setContentText((argument as Map<String, String>)["text"])
                            .build()
                        val notificationManager: NotificationManager = applicationContext.getSystemService(
                            NOTIFICATION_SERVICE
                        ) as NotificationManager
                        val channel = NotificationChannel(
                            examUpdateChannelID,
                            examUpdateChannelName,
                            NotificationManager.IMPORTANCE_DEFAULT
                        )
                        notificationManager.createNotificationChannel(channel)
                        notificationManager.notify(examUpdateChannelID.toInt(), notification)
                    }
                } else if (method == "stopService") {
                    stopSelf(-1)
                }
            }
        )
        wearEngine = WearEngine()
        wearEngine.initClient(applicationContext)
        p2pConnectSetup = fun(_:String){
            val selectResult = wearEngine.selectDevice(selectedWearDeviceUUID)
            Log.d(tag,"Select device ${if(selectResult) "success" else "failed"}, ${sharedPreferences.getString("flutter.selectedWearDeviceUUID", "")?:""}")
            val serviceContext = this
            wearEngine.receiveMessage(
                onReceiveMessage = fun(msgFromWear: Message?) {
                    val data = msgFromWear?.let { String(it.data) }
                    Log.d(tag,"Receive message from wear: $data")
                    val dataSplitLine = data?.split("\n")
                    if(!dataSplitLine.isNullOrEmpty()) {
                        for (i in dataSplitLine.indices) {
                            val dataSplit = dataSplitLine[i].split(" ")
                            if(dataSplit.isNotEmpty()) {
                                val arguments = mutableMapOf<String, String>()
                                if(dataSplit.size % 2 == 1) {
                                    for (index in 1 until dataSplit.size step 2){
                                        arguments[dataSplit[index]] = dataSplit[index + 1]
                                    }
                                }
                                val handler = Handler(serviceContext.mainLooper)
                                handler.post {
                                    userUtilRequest.invoke(
                                        dataSplit[0],
                                        arguments,
                                        fun(data: Any?) {
                                            Log.d(tag,"${dataSplit[0]}: $data")
                                            val file = File(File(applicationContext.cacheDir.toURI()), dataSplit[0])
                                            file.writeText(data.toString())
                                            wearEngine.sendFile(file.absolutePath)
                                        },
                                        fun(errorCode: String, errorMessage: String?, _: Any?) {
                                            wearEngine.sendMessage("Error: $errorCode, $errorMessage")
                                            Log.e(tag,"${dataSplit[0]} Error: $errorCode, $errorMessage")
                                        }
                                    )
                                }
                            }
                        }
                    }
                },
                onFailure = fun(e: Exception?) {
                    Log.e("WearEngine","receiveMessage onFailure: $e")
                })
        }
        GlobalScope.launch(Dispatchers.Main)  {
            delay(50)
            if(!startCommandRunOnce) {
                onStartCommand(
                    Intent(
                        applicationContext,
                        PrescoreService::class.java
                    ), 0, 0
                )
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startCommandRunOnce = true
        Log.d(tag, "onStartCommand $intent")
        val checkExams : Boolean
        val checkExamsInterval : Int
        val deviceUUID : String
        val enableWearService : Boolean
        val showMoreSubject : Boolean
        if(intent?.hasExtra("checkExams") == true) {
            Log.d(tag, "changeServiceStatus by read intent $intent")
            checkExams = intent.getBooleanExtra("checkExams", false)
            checkExamsInterval = intent.getIntExtra("checkExamsInterval",6)
            deviceUUID = intent.getStringExtra("selectedWearDeviceUUID") ?:""
            enableWearService = intent.getBooleanExtra("enableWearService", false)
            showMoreSubject = intent.getBooleanExtra("showMoreSubject", false)
        } else {
            Log.d(tag, "changeServiceStatus by read sharedPreferences")
            val sharedPreferences: SharedPreferences = applicationContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            checkExams = sharedPreferences.getBoolean("flutter.checkExams", false)
            checkExamsInterval = sharedPreferences.getLong("flutter.checkExamsInterval", 6).toInt()
            deviceUUID = sharedPreferences.getString("flutter.selectedWearDeviceUUID", "")?:""
            enableWearService = sharedPreferences.getBoolean("flutter.enableWearService", false)
            showMoreSubject = sharedPreferences.getBoolean("flutter.showMoreSubject", false)
        }
        Log.d(tag, "changeServiceStatus checkExams $checkExams checkExamsInterval $checkExamsInterval deviceUUID $deviceUUID enableWearService $enableWearService")
        selectedWearDeviceUUID = deviceUUID
        if(enableWearService) {
            wearEngine.wearEngineConnectRegister(applicationContext, fun() = wearEngine.getBoundDevices(p2pConnectSetup))
            wearEngine.getBoundDevices(p2pConnectSetup)
        } else {
            //wearEngine.unregisterReceiver()
            wearEngine = WearEngine()
            wearEngine.initClient(applicationContext)
            wearEngine.wearEngineConnectRegister(applicationContext, fun() {})
        }
        sleep(50)
        userUtilRequest.invoke("changeServiceStatus",
            mapOf("checkExams" to checkExams, "checkExamsInterval" to checkExamsInterval, "showMoreSubject" to showMoreSubject)
        )
        return START_STICKY
    }
    override fun onBind(p0: Intent?): IBinder? {
        return null
    }
    override fun onDestroy() {
        stopForeground(STOP_FOREGROUND_REMOVE)
        if(this::wakeLock.isInitialized) {
            wakeLock.release()
        }
        userUtilRequest.releaseFlutterEngine()
        super.onDestroy()
    }
}