import UIKit
import Flutter
import CoreMotion
import Foundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let press_channel = "pressure_sensor"//Channel for communicating with flutter pressure sensor
    let prox_channel = "proximity_channel"//Channel for communicating with flutter proximity sensor
    let acc_channel = "accelerometer_channel"//Channel for communicating with flutter accelerometer sensor
    let gyro_channel = "gyroscope_channel"//Channel for communicating with flutter gyroscope sensor
    let magn_channel = "magnetometer_channel"//Channel for communicating with flutter magnetometer sensor
    let pressure_channel = "pressure_channel"//Pressure event channel for communicating with flutter sensor

    let pressureStreamHandler = PressureStreamHandler()

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    let presschannel = FlutterMethodChannel(name: press_channel, binaryMessenger: controller.binaryMessenger)

    presschannel.setMethodCallHandler({
        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
        switch call.method {
        case "isSensorAvailable":
            result(CMAltimeter.isRelativeAltitudeAvailable())
        default:
            result(FlutterMethodNotImplemented)
        }
    })

//    let proxchannel = FlutterMethodChannel(name: prox_channel, binaryMessenger: controller.binaryMessenger)
//
//        proxchannel.setMethodCallHandler({
//            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
//            switch call.method {
//            case "isSensorAvailable":
//                result(UIDevice.isProximityMonitoringEnabled)
//            default:
//                result(FlutterMethodNotImplemented)
//            }
//        })

//     let accchannel = FlutterMethodChannel(name: acc_channel, binaryMessenger: controller.binaryMessenger)
//
//     accchannel.setMethodCallHandler({
//         (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
//         switch call.method {
//         case "isSensorAvailable":
//             result(CMSensorRecorder.isAccelerometerRecordingAvailable())//an den douleuei to epitaxinsionometro ftaei auto
//         default:
//             result(FlutterMethodNotImplemented)
//         }
//     })

//    let gyrochannel = FlutterMethodChannel(name: gyro_channel, binaryMessenger: controller.binaryMessenger)
//
//    gyrochannel.setMethodCallHandler({
//        (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
//        switch call.method {
//        case "isSensorAvailable":
//            result(CMGyroData.rotationRate != nil)//an den douleuei to gyroskopio ftaei auto
//        default:
//            result(FlutterMethodNotImplemented)
//        }
//    })

//     let magnchannel = FlutterMethodChannel(name: magn_channel, binaryMessenger: controller.binaryMessenger)
//
//         magnchannel.setMethodCallHandler({
//             (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
//             switch call.method {
//             case "isSensorAvailable":
//                 result(CMagnetometerData.magneticField != nil)//an den douleuei to magnetometro ftaei auto
//             default:
//                 result(FlutterMethodNotImplemented)
//             }
//         })

    let pressurechannel = FlutterEventChannel(name: pressure_channel, binaryMessenger: controller.binaryMessenger)
    pressurechannel.setStreamHandler(pressureStreamHandler)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

class PressureStreamHandler: NSObject, FlutterStreamHandler {
    let altimeter = CMAltimeter()
    private let queue = OperationQueue()

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {

        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: queue) { (data,error) in
                if data != nil {
                //Get pressure
                let pressurePascals = data?.pressure
                    events(pressurePascals!.doubleValue * 10.0)
             }
            }
        }
        return nil
    }

    func onCancel(withArguments arguments:Any?) -> FlutterError? {
        altimeter.stopRelativeAltitudeUpdates()
        return nil
    }

}
