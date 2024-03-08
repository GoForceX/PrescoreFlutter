/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2020-2020. All rights reserved.
 */

package com.bjbybbs.prescore_flutter.util

import android.app.Activity
import android.content.Context
import android.os.Process
import android.util.Log
import com.huawei.hmf.tasks.OnFailureListener
import com.huawei.hmf.tasks.OnSuccessListener
import com.huawei.wearengine.HiWear
import com.huawei.wearengine.auth.AuthCallback
import com.huawei.wearengine.auth.AuthClient
import com.huawei.wearengine.auth.Permission
import com.huawei.wearengine.client.ServiceConnectionListener
import com.huawei.wearengine.client.WearEngineClient
import com.huawei.wearengine.device.Device
import com.huawei.wearengine.device.DeviceClient
import com.huawei.wearengine.notify.NotifyClient
import com.huawei.wearengine.p2p.Message
import com.huawei.wearengine.p2p.P2pClient
import com.huawei.wearengine.p2p.PingCallback
import com.huawei.wearengine.p2p.Receiver
import com.huawei.wearengine.p2p.SendCallback
import java.io.File
import java.io.UnsupportedEncodingException

class WearEngine {
    private var p2pClient: P2pClient? = null
    private var deviceClient: DeviceClient? = null
    private var notifyClient: NotifyClient? = null
    var deviceList: MutableList<Device> = ArrayList<Device>()
    private var selectedDevice: Device? = null
    private var connectedDevice: Device? = null
    private var sendMessage: Message? = null
    private var wearEngineClient: WearEngineClient? = null
    private val peerPkgName: String = "com.liteharmony.prescore"
    private val peerFingerPrint: String = "com.liteharmony.prescore_BO56cZy1BgxAru2fBc+kIOHQBN9oipovHVSkmtroxPxENIbU362qh9eq1jU1RgLHU/QI9CEIzKI+UbrXPLk3azs="
    private val TAG = "WearEngine"
    private lateinit var receiver: Receiver
    fun initClient(context: Context) {
        deviceClient = HiWear.getDeviceClient(context)
        p2pClient = HiWear.getP2pClient(context)
        notifyClient = HiWear.getNotifyClient(context)
        p2pClient?.setPeerPkgName(peerPkgName)
        p2pClient?.setPeerFingerPrint(peerFingerPrint)
    }
    fun wearEngineConnectRegister(context: Context, onServiceConnect: (() -> Unit)? = null, onServiceDisconnect: (() -> Unit)? = null) {
        val serviceConnectionListener: ServiceConnectionListener =
            object : ServiceConnectionListener {
                override fun onServiceConnect() {
                    onServiceConnect?.invoke()
                }
                override fun onServiceDisconnect() {
                    onServiceDisconnect?.invoke()
                }
            }
        wearEngineClient = HiWear.getWearEngineClient(context, serviceConnectionListener)
        wearEngineClient?.registerServiceConnectionListener()
    }
    fun requestPermission(activity: Activity) {
        val authClient: AuthClient = HiWear.getAuthClient(activity)
        val authCallback: AuthCallback = object : AuthCallback {
            override fun onOk(permissions: Array<Permission?>?) {
            }
            override fun onCancel() {
            }
        }
        authClient.requestPermission(authCallback, Permission.DEVICE_MANAGER, Permission.NOTIFY, Permission.SENSOR)
            .addOnSuccessListener(object : OnSuccessListener<Void?> {
                override fun onSuccess(successVoid: Void?) {
                }
            })
            .addOnFailureListener(object : OnFailureListener {
                override fun onFailure(e: Exception?) {
                }
            })
    }
    fun getBoundDevices(onResult: ((result: String) -> Unit)? = null) {
        deviceClient?.bondedDevices
            ?.addOnSuccessListener { devices ->
                deviceList.clear()
                deviceList.addAll(devices!!)
                Log.d(TAG,"getBoundDevices success")
                Log.d(TAG,devices.toString())
                onResult?.invoke("success")
            }
            ?.addOnFailureListener { e ->
                Log.d(TAG,"getBoundDevices failed, $e")
                onResult?.invoke(e.toString())
            }
        if (deviceList.isNotEmpty()) {
            for (device in deviceList) {
                if (device.isConnected) {
                    connectedDevice = device
                }
            }
        }
    }
    fun pingBoundDevices(
        onPingResult: (result: Int) -> Unit,
        onSuccess: (result: Void?) -> Unit,
        onFailure: (e: Exception?) -> Unit) {
        if (!checkSelectedDevice()) {
            return
        }
        p2pClient?.ping(selectedDevice, object : PingCallback {
            override fun onPingResult(result: Int) {
                onPingResult.invoke(result)
            }
        })?.addOnSuccessListener(object : OnSuccessListener<Void?> {
            override fun onSuccess(result: Void?) {
                onSuccess.invoke(result)
            }
        })?.addOnFailureListener(object : OnFailureListener {
            override fun onFailure(e: Exception?) {
                onFailure.invoke(e)
            }
        })
        return
    }
    fun unregisterReceiver() {
        try {
            p2pClient?.unregisterReceiver(receiver)
        } catch(_: Exception) {}
    }
    fun receiveMessage(
        onReceiveMessage: (message: Message?) -> Unit,
        onSuccess: (avoid: Void?) -> Unit = {}, onFailure: (Exception?) -> Unit = {}) {
        if (!checkSelectedDevice()) {
            return
        }
        receiver = object : Receiver {
            override fun onReceiveMessage(message: Message?) {
                onReceiveMessage.invoke(message)
            }
        }
        val receiverPid = Process.myPid()
        val receiverHashCode = System.identityHashCode(receiver)
        Log.d(TAG,"receiver pid is:$receiverPid$, code is $receiverHashCode")
        p2pClient?.registerReceiver(selectedDevice, receiver)
            ?.addOnSuccessListener(object : OnSuccessListener<Void?> {
                override fun onSuccess(avoid: Void?) {
                    onSuccess.invoke(avoid)
                }
            })?.addOnFailureListener(object : OnFailureListener {
                override fun onFailure(e: Exception?) {
                    onFailure.invoke(e)
                }
            })
    }
    fun sendFile(sendFilePath: String?) {
        val sendFile = File(sendFilePath)
        val builder = Message.Builder()
        builder.setPayload(sendFile)
        val fileMessage = builder.build()
        p2pClient!!.send(selectedDevice, fileMessage, object : SendCallback {
            override fun onSendResult(resultCode: Int) {
            }
            override fun onSendProgress(progress: Long) {
            }
        }).addOnSuccessListener {
        }.addOnFailureListener {
        }
    }
    fun sendMessage(message: String, onSendResult: (message: Int?) -> Unit = {}) {
        if (!checkSelectedDevice()) {
            return
        }
        if (message.isNotEmpty()) {
            val builder: Message.Builder = Message.Builder()
            try {
                builder.setPayload(message.toByteArray(charset("UTF-8")))
            } catch (e: UnsupportedEncodingException) {
                Log.e(TAG, "set sendMessageStr UnsupportedEncodingException")
            }
            sendMessage = builder.build()
        }
        if (sendMessage == null || sendMessage?.getData()?.isEmpty() == true) {
            return
        }
        val sendCallback: SendCallback = object : SendCallback {
            override fun onSendResult(resultCode: Int) {
                onSendResult.invoke(resultCode)
            }

            override fun onSendProgress(progress: Long) {
            }
        }
        p2pClient?.send(selectedDevice, sendMessage, sendCallback)
            ?.addOnSuccessListener(object : OnSuccessListener<Void?> {
                override fun onSuccess(result: Void?) {
                    Log.d(TAG,"sendMessage onSuccess")
                }
            })?.addOnFailureListener(object : OnFailureListener {
                override fun onFailure(e: Exception?) {
                    Log.d(TAG,"sendMessage onFailure: $e")
                }
            })
    }
    private fun checkSelectedDevice(): Boolean {
        if (selectedDevice == null) {
            return false
        }
        return true
    }
    fun selectDevice(UUID: String): Boolean {
        Log.d("WearEngine","deviceList: $deviceList")
        for(device in deviceList) {

            if (device.uuid == UUID){
                selectedDevice = device
                return true
            }
        }
        return false
    }
}