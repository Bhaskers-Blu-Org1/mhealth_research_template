// Copyright © 2018 IBM.

import UIKit
import ResearchKit
import UserNotifications
import CoreLocation
import PDFKit
import SwiftNotes

class SetupViewController: UIViewController, CLLocationManagerDelegate {
    
    //MARK: Buttons
    @IBOutlet weak var consentButton: UIButton!
    @IBOutlet weak var hkAccess: UIButton!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var completeEnrollmentButton: UIButton!
    @IBOutlet weak var notificationsButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    
    //MARK: Labels
    @IBOutlet weak var consentLabel: UILabel!
    @IBOutlet weak var hkLabel: UILabel!
    @IBOutlet weak var notificationsLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    //MARK: Button actions
    @IBAction func completeEnrollmentButtonPress(_ sender: Any) {
        //SYNC HealthKit profile data to server.
        // Note that this requires at least one point of step data to be in HealthKit. If there's no step data at all, the user won't be allowed to proceed past setup.
        do {
            let test = try HealthKitData.getProfile()
            callAPIc(type: "Profile", id: studyID, pw: sKey, params: test,  onCompletion: { resp in
                if resp[1] == "200" {
                    syncDate["Profile"] = Date()
                    syncTypes["Profile"] = true
                    self.welcomeMessage(completion: {result in
                        if result {
                            print(result)
                            self.performSegue(withIdentifier: "enrollSegue", sender: self)
                        }
                    })
                } else {
                    syncTypes["Profile"] = false
                    print("Sync error for Profile data, server response \(resp[1])")
                }
                
            }) {(error) in print("ERROR uploading profile info!. Error: \(error) ")
                
            }
            
        } catch let error {
            print(error)
        }
    }

    
    @IBAction func consentTap(_ sender: Any) {
        let taskViewController = ORKTaskViewController(task: ConsentTask, taskRun: nil)
        taskViewController.view.tintColor = UIColor.blue // pick the color
        taskViewController.delegate = self as ORKTaskViewControllerDelegate
        present(taskViewController, animated: true, completion: nil)
    }
    
    @IBAction func healthKitAccess(_ sender: Any) {
       
        let dgroup = DispatchGroup()
        dgroup.enter()
        hkAllowed = healthKitMan.authorizeHealthkit()
        dgroup.leave()
        
        do {
            HealthKitData.getTodaysSteps() {steps in
                if steps.contains("not") || steps.contains("N/A")  {
                    //print("not authorized: \(steps)")
                     hkAllowed = false
                } else {
                     hkAllowed = true
                     self.nextSteps()
                }
                
            }
        }
 
    }
   
    @IBAction func enableLocationButton(_ sender: Any) {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined, .restricted, .denied:
            print("No access")
        case .authorizedAlways, .authorizedWhenInUse:
            locationEnabled = true
            print("Access")
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
            self.locationManager.startUpdatingLocation()
            self.locationManager.stopUpdatingLocation()
        }
            self.nextSteps()
    }
    
    @IBAction func enableNotificationsButton(_ sender: Any) {
        let dgroup = DispatchGroup()
        dgroup.enter()
        if hkAllowed == false {
            self.hkLabel.text = "You must enable access HealthKit Step data to proceed."
        } else {
            UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
                switch notificationSettings.authorizationStatus {
                case .notDetermined:
                    notifications.requestAuthorization(completionHandler: { (success) in
                        guard success else {
                            notificationsEnabled = true
                            dgroup.leave()
                            return
                        }
                    })
                case .authorized:
                    notificationsEnabled = true
                    self.nextSteps()
                      dgroup.leave()
                case .denied:
                    notificationsEnabled = false
                    print("Application Not Allowed to Display Notifications")
                      dgroup.leave()
                case .provisional:
                    notificationsEnabled = true
                
                    dgroup.leave()
                    
                }
            }
            let grantedSettings = UIApplication.shared.currentUserNotificationSettings
            if (grantedSettings?.types.rawValue)! & UIUserNotificationType.alert.rawValue != 0 {
                notificationsEnabled = true // Alert permission granted
            }
            dgroup.notify(queue: .main) {
                 self.nextSteps()
            }
           
        }
    }
    
    func welcomeMessage(completion: @escaping ((Bool) -> Void)) {
        let alertController = UIAlertController(title: "Welcome!", message: "Welcome to the study! ", preferredStyle: UIAlertControllerStyle.alert)
        
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alertController.dismiss(animated: true, completion: nil)
            completion(true) // true signals "YES"
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: Location Manager setup
    var locationManager: CLLocationManager!
    var currentLocation: CLLocation!
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                    locationButton.isEnabled = false
                    locationButton.setTitle("✅ Location accessible", for: UIControlState.disabled)
                    locationLabel.text = "Thank you for allowing access to your location."
                    completeEnrollmentButton.isEnabled = true
                    completeEnrollmentButton.setTitle("👉 Enroll in the study", for: UIControlState.normal)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        let latestLocation: CLLocation = locations[locations.count - 1]
        print("Lat: \(String(format: "%.4f", latestLocation.coordinate.latitude)), and Long: \(String(format: "%.4f", latestLocation.coordinate.longitude)), and horiz: \(String(format: "%.4f", latestLocation.horizontalAccuracy)), and alt: \(String(format: "%.4f", latestLocation.altitude)), and verti: \(String(format: "%.4f", latestLocation.verticalAccuracy))")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    //MARK: ViewDidLoad
    override func viewDidLoad() {
        
        nextSteps()
        super.viewDidLoad()
    }
    
    //MARK: nextSteps
    // Logic to change steup screen UI elements as the user enables access to data
    func nextSteps() {
        if consentSigned {
            consentButton.isEnabled = false
            consentButton.setTitle("✅ Consent form signed", for: UIControlState.disabled)
            consentLabel.text = "Thank you for consenting to this study."
            hkAccess.isEnabled = true
            hkAccess.setTitle("👉 Tap here next.", for: UIControlState.normal)
            if hkAllowed {
                hkAccess.isEnabled = false
                hkAccess.setTitle("✅ HealthKit accessible", for: UIControlState.disabled)
                hkLabel.text = "Thank you for contributing your HealthKit data to this study."
                notificationsButton.isEnabled = true
                notificationsButton.setTitle("👉 Tap here", for: UIControlState.normal)
                if notificationsEnabled {
                    notificationsButton.isEnabled = false
                    notificationsButton.setTitle("✅ Notifications enabled", for: UIControlState.disabled)
                    notificationsLabel.text = "Thank you for enabling notificaitons."
                    locationButton.isEnabled = true
                    locationButton.setTitle("👉 Finally, tap here", for: UIControlState.normal)
                    if locationEnabled {
                        locationButton.isEnabled = false
                        locationButton.setTitle("✅ Location accessible", for: UIControlState.disabled)
                        locationLabel.text = "Thank you for allowing access to your location."
                        completeEnrollmentButton.isEnabled = true
                        completeEnrollmentButton.setTitle("👉 Enroll in the study", for: UIControlState.normal)
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension SetupViewController : ORKTaskViewControllerDelegate {
    //Manage consent signing
    func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
        
        print("entering the dismiss function")
        if error != nil {
            NSLog("Error: \(String(describing: error))")
        }
        else {
          
            switch reason.rawValue {
            case 2:
                if let signatureResult =
                    taskViewController.result.stepResult(forStepIdentifier:
                        "ConsentReviewStep"
                        )?.firstResult as? ORKConsentSignatureResult {
                    if signatureResult.consented {
                        var fName = " "
                        var lName = " "
                        if let uFNAME = signatureResult.signature?.givenName {
                            fName = uFNAME
                        }
                        if let uLNAME = signatureResult.signature?.familyName {
                            lName = uLNAME
                        }
                       
                        print("first name: \(fName) and last name: \(lName)") // THIS WORKS
                        let encrypted_fn = encrypt(str_to_encrypt: fName)
                        let encrypted_ln = encrypt(str_to_encrypt: lName)
                        let uploadGroup = DispatchGroup()
                        uploadGroup.enter()
                        callAPIc(type: "ID", id: apiID, pw: apiPW, params: [["firstName" : encrypted_fn, "lastName" : encrypted_ln, "appleId" : NSUUID().uuidString]], onCompletion: { resp in
                            print("type: \(resp[0]) studyID: \(resp[1])")
                            
                        }) {(error) in print("assigning studyID. Error: \(error) ")
                            
                        }
                        uploadGroup.leave()
                        sleep(2) // pauuse and wait for return)
                         uploadGroup.notify(queue: .main) {
                            print("studyID \(studyID) and skey \(sKey)")
                        }
                        //setUpID(fn: fName, ln: lName, uid: NSUUID().uuidString)
                        
                        //let result = taskViewController.result
                        if let stepResult = taskViewController.result.stepResult(forStepIdentifier:"ConsentReviewStep")?.firstResult as? ORKConsentSignatureResult {
                            if let signatureResult = taskViewController.result.stepResult(forStepIdentifier: "ConsentReviewStep")?.firstResult as? ORKConsentSignatureResult {
                                signatureResult.apply(to: consentDocument)
                                consentDocument.makePDF { (data, error) -> Void in
                                    print("This is studyID upon consent: \(studyID)")
                                    var docURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last
                                    docURL = docURL?.appendingPathComponent(studyID + ".pdf")
                                    do {
                                        let pdfView = PDFView()
                                        try data?.write(to: docURL!, options: .atomicWrite)// 
                                        callConsentAPI(id: apiID, pw: apiPW, onCompletion: { result in
                                            print("ack, the result is here: \(result)")
                                            if result.contains("ok") && studyID != "" {
                                                consentSigned = true
                                                self.nextSteps()
                                                self.hkAccess.isEnabled = true
                                                consentDate = Date()
                                            } else {
                                                consentSigned = false
                                                self.hkAccess.isEnabled = false
                                                consentDate = Date()
                                            }
                                        }) {(error) in
                                            print("sending consent PDF to API error: \(error) ")
                                            consentSigned = false
                                            self.hkAccess.isEnabled = false
                                            consentDate = Date()
                                        }
                                    } catch {
                                        // failed to write
                                    }
                                 
                                }
                            }
                        }

                    } else {
                        consentSigned = false
                    }
                    
                }
                
            default: break
            }
        }
        // Dismiss the task’s view controller when the task finishes
        taskViewController.dismiss(animated: true, completion: nil)
    }
}
