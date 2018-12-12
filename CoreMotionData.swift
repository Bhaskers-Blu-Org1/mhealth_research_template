// Copyright © 2018 IBM.

import Foundation
import CoreMotion

let cmManager = CMMotionActivityManager()
let pedometer = CMPedometer()
let motionManager = CMMotionManager()

class CoreMotionData {
    
    
    class func getStepCountFrom(startDate: Date, completion: @escaping (_ value: String) -> ()) {
        var step_count = "0"
        pedometer.queryPedometerData(from: Calendar.current.startOfDay(for: startDate), to: Date()) {
            pedometerData, error in
            if let error = error {
                print(error.localizedDescription)
            }
            if let pedometerData = pedometerData {
                DispatchQueue.main.async {
                    step_count = String(describing: pedometerData.numberOfSteps)
                    completion(step_count)
                }
            }
        }
    }
    
    class func getPedometerData(startDate: Date, endDate: Date, completion: @escaping (_ value: [String: String]) -> ()) {
        var results = ["start_date": "", "end_date": "", "step_count": "", "distance": "", "cadence": "", "pace": "", "avg_pace": "", "floors_asc": "", "floors_desc": ""]
        pedometer.queryPedometerData(from: Calendar.current.startOfDay(for: startDate), to: Date()) {
            pedometerData, error in
            if let error = error {
                print(error.localizedDescription)
            }
            if let pedometerData = pedometerData {
                DispatchQueue.main.async {
                
                    results["studyId"] = studyID
                    results["start_date"] = String(describing: pedometerData.startDate)
                    results["end_date"] = String(describing: pedometerData.endDate)
                    results["step_count"] = String(describing: pedometerData.numberOfSteps)
                   
                    if let s = pedometerData.distance {
                        results["distance"] = String(describing: s)
                    } else {
                        results["distance"] = " "
                    }
                    
                    if let s = pedometerData.currentCadence {
                        results["cadence"] = String(describing: s)
                    } else {
                        results["cadence"] = " "
                    }
                   
                    if let s = pedometerData.currentPace {
                        results["pace"] = String(describing: s)
                    } else {
                        results["pace"] = " "
                    }
                    
                    if let s = pedometerData.averageActivePace {
                        results["avg_pace"] = String(describing: s)
                    } else {
                        results["avg_pace"] = " "
                    }
                    
                    if let s = pedometerData.floorsAscended {
                        results["floors_asc"] = String(describing: s)
                    }else {
                         results["floors_asc"] = " "
                    }
                    
                    if let s = pedometerData.floorsDescended {
                        results["floors_desc"] = String(describing: s)
                    } else {
                        results["floors_desc"] = " "
                    }
                
                    completion(results)
                }
            }
        }
    }
    
    class func getCMData(from start: Date) {
        cmManager.queryActivityStarting(from: start, to: Date(), to: .main) { motionActivities, error in
            if let error = error {
                print("queryActivityStarting Error: \(error.localizedDescription)")
                return
            }
            if let mA = motionActivities {
                if let item = mA.last {
                    CMactivityTimeLine.append(["studyId" : studyID, "start_date" : String.init(describing: item.startDate), "end_date" : String.init(describing: Date()), "automotive" : String(item.automotive), "cycling" : String(item.cycling), "running" : String(item.running), "walking" : String(item.walking), "stationary" : String(item.stationary), "unknown" : String(item.unknown), "confidence" : String(item.confidence.rawValue)])

                }
                
            }
            
        }
        getPedometerData(startDate: start, endDate: Date())  { results in
            CMstepsTimeLine.append(results)
        }
    }
    
    class func startUpdates(from start: Date) {
        cmManager.queryActivityStarting(from: Date() - 60*100, to: Date(), to: .main) { motionActivities, error in
            if let error = error {
                print("error: \(error.localizedDescription)")
                return
            }
            if let mA = motionActivities {
                print(mA)
            }
        }
        
        var timer: Timer!
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
        motionManager.startMagnetometerUpdates()
        motionManager.startDeviceMotionUpdates()
        
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
            
        
        pedometer.startUpdates(from: Date(), withHandler: { (pedometerData, error) in
            
            if let error = error {
                print(error.localizedDescription)
            }
            if let pedData = pedometerData{
                //debug
                print("steps: \(String(describing: pedData.numberOfSteps))")
                print("distance: \(String(describing: pedData.distance))")
            }
        })
    }
    
    @objc func update() {
        if let accelerometerData = motionManager.accelerometerData {
            print(accelerometerData)
        }
        if let gyroData = motionManager.gyroData {
            print(gyroData)
        }
        if let magnetometerData = motionManager.magnetometerData {
            print(magnetometerData)
        }
        if let deviceMotion = motionManager.deviceMotion {
            print(deviceMotion)
        }
    }
}
