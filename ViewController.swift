// Copyright © 2018 IBM.

import UIKit // This is because this class is tied to a UI
import ResearchKit // This is for the informed consent process
import EventKit // This is for calednar integration
import UserNotifications // This is for notifications
import CoreLocation // This is for accessing location data
import CoreMotion // This is for access pedometer/motion data
import HealthKit // This is to access the HealthKit data store

var hiddenCounter = 0
var showNow = false

class ViewController: UIViewController, CLLocationManagerDelegate {

    public let cmManager = CMMotionActivityManager()
    let pedometer = CMPedometer()
    //MARK: Temp vars
    var h = false
    var b = false
    var hk = false
    var loca = false
    var notif = false
    var cale = false
    
    //MARK: Buttons
    @IBOutlet weak var SelectedThingButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var setBaselineButton: UIButton!
    
    //MARK: Labels
    @IBOutlet weak var okLabel: UILabel!
    @IBOutlet weak var lastSyncLabel: UILabel!
    @IBOutlet weak var studyIDLabel: UILabel!
    @IBOutlet weak var SelectedThingLabel: UILabel!
    @IBOutlet weak var baselineStepsLabel: UILabel!
    @IBOutlet weak var weeksStepsLabel: UILabel!
    @IBOutlet weak var baselineStepsName: UILabel!
    @IBOutlet weak var todaysStepsLabel: UILabel!
    
    //MARK: Button actions
    @IBAction func SelectedThingButton(_ sender: Any) {
        self.performSegue(withIdentifier: "SelectedThingSegue", sender: self)
    }

    @IBAction func hiddenButton(_ sender: Any) {
        hiddenCounter += 1
        print(hiddenCounter)
        if hiddenCounter % 5 == 4 {
            //if hidden option
            if SelectedThingSelected {
                SelectedThingButton.setTitle("✅ SelectedThing selected", for: UIControlState.normal)
            }
            if baseline > 0 {
                setBaselineButton.setTitle("✅ Baseline selected ", for: UIControlState.normal)
            }
            
            showNow = true
            let alert = UIAlertController(title: "For research admins only. \(group.prefix(1))-\(group.suffix(1))", message: "Please enter the passcode:", preferredStyle: .alert)
            
            //2. Add the text field. You can configure it however you need.
            alert.addTextField { (textField) in
                textField.text = ""
            }
            
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
                let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
                if textField?.text == "1" {
                    doneSetup = false
                    print("The baseline period is over. \(group)")
                    //MODIFIED FOR NEW GROUPS
                    if (group.contains("1") || group.contains("2") ){ // Enable SelectedThing buttons and label for treatment group.
                        self.SelectedThingLabel.isHidden = false
                        self.SelectedThingButton.isHidden = false
                        self.SelectedThingButton.isEnabled = true
                      
                    }
                    // Every group can set a baseline, so we'll show these.
                  
                    self.setBaselineButton.isHidden = false
                    self.setBaselineButton.isEnabled = true
                    self.okButton.isHidden = false
                } else {
                    //self.SelectedThingLabel.isHidden = true
                    self.SelectedThingButton.isHidden = true
                   
                    self.setBaselineButton.isHidden = true
                    self.okButton.isHidden = true
                    showNow = false
                }
                print("Text field: \(String(describing: textField?.text))")
            }))
            
            // 4. Present the alert.
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @IBAction func viewStepsButton(_ sender: Any) {
        self.performSegue(withIdentifier: "stepsSegue", sender: self)
    }
    
    @IBAction func viewInstructionsButton(_ sender: Any) {
        self.performSegue(withIdentifier: "instructionsSegue", sender: self)
    }
    
    @IBAction func setBaselineButton(_ sender: Any) {
        self.performSegue(withIdentifier: "setBaselineSegue", sender: self)
    }
    
    @IBAction func notify(_ sender: Any) {
        // This will raise a notification in 10 seconds as a test.
        ViewController.scheduleNotification(category: "_", typeOfN: "test")
    }
    
    @IBAction func queryTimeSeries(_ sender: Any) {
        
        uploadData()
        
    }
    
    @IBAction func okDoneButton(_ sender: Any) {
        syncStudyCoordinatorWork()
    }
    
    @IBAction func hiddenUploadStatusButton(_ sender: Any) {
        
        // This function defines the behavior for a hidden function
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
       
        // Alert content goes here.
        let alert = UIAlertController(title: "Upload status", message: "Baseline: \(syncTypes["Baseline"]!), last update on: \(df.string(from:syncDate["Baseline"]!)) \nProfile: \(syncTypes["Profile"]!), last update on: \(df.string(from:syncDate["Profile"]!)) \nHealthKit: \(syncTypes["HK"]!), last update on: \(df.string(from:syncDate["HK"]!)) \nNotifications: \(syncTypes["Notification"]!), last update on: \(df.string(from:syncDate["Notification"]!)) \nLocation: \(syncTypes["Location"]!), last update on: \(df.string(from:syncDate["Location"]!)) \nCalendar: \(syncTypes["Calendar"]!), last update on: \(df.string(from:syncDate["Calendar"]!)) ", preferredStyle: .alert)
        
        // 2. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: { [weak alert] (_) in
            
        }))
        // 3. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    func syncStudyCoordinatorWork() {
       
        let dGroup = DispatchGroup()
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        
        if baseline > 0 {
            print("baseline")
            if ((group.contains("1") || group.contains("2")) && SelectedThing != ""){
                //SYNC SelectedThing data to server
                dGroup.enter()
                callAPIc(type: "SelectedThing", id: studyID, pw: sKey, params: [["studyId" : studyID, "SelectedThing_ID" : "NA", "SelectedThing_time" : "\(df.string(from: SelectedThingTime))", "SelectedThing_description" : SelectedThingDetails["SelectedThing"]!, "SelectedThing_notes" : SelectedThingDetails["Notes"]!]], onCompletion:  { (result) in
                    if result[1] == "200" {
                        
                        self.h = true

                        syncDate["SelectedThing"] = Date()
                        syncTypes["SelectedThing"] = true
                        if group.contains("2") {
                            // Schedule SelectedThing reminders for group Treatment 2
                            ViewController.scheduleNotification(category: "", typeOfN: "reminderBefore")
                            ViewController.scheduleNotification(category: "", typeOfN: "reminderAfter")
                            // SelectedThing data synced!
                        }
                    } else {
                        print("problemo with SelectedThing data upload.... type: \(result[0]) that had response: \(result[1])")
                        syncTypes["SelectedThing"] = false
                    }
                    dGroup.leave()
                }){ (error) in
                    print(error.domain)
                    syncTypes["SelectedThing"] = false
                    self.okLabel.text = "Sync error for SelectedThing data. Contact research admin for help."
                    dGroup.leave()
                }
                
            } else {
                self.h = true
            }
            
            //SYNC Baseline
            dGroup.enter()
            callAPIc(type: "Baseline", id: studyID, pw: sKey, params: [["studyId" : studyID, "baseline" : "\(baseline)"]], onCompletion:  { (result) in
                if result[1] == "200" {

                    syncDate["Baseline"] = Date()
                    syncTypes["Baseline"] = true
                    self.b = true
                    // self.finishStudyCoordinatorWork()
                    print("baseline is GOOD")
                } else {
                    print("problemo with baseline data upload type: \(result[0]) that had response: \(result[1])")
                    syncTypes["Baseline"] = false
                }
                dGroup.leave()
            }){ (error) in
                print(error.domain)
                syncTypes["Baseline"] = false
                // print("Sync error for SelectedThing data, server response \(ht[1])")
                self.okLabel.text = "Sync error for Basline data. Contact research admin for help."
                dGroup.leave()
            }
            
            dGroup.notify(queue: .main) {
                print("IN the notify!")
                if self.b && self.h { //if sync went OK for both
                    let center = UNUserNotificationCenter.current()
                    center.removeAllPendingNotificationRequests()
                    self.finishStudyCoordinatorWork()
                    showNow = false
                } else{
                    print("Not both ok! b: \(self.b) h: \(self.h)")
                }
            }
        }
    }
    
    
    func finishStudyCoordinatorWork() {
        //MODIFIED FOR NEW GROUPS ALMOST DONE
        if (group.contains("0") && b == true ) || ((group.contains("1") || group.contains("2"))  && b == true && h == true) { //If control and baseline synced, or treatment and SelectedThing AND baseline synced
            doneSetup = true
            if group.contains("0") || group.contains("1") {
                // Schedule BCE notifications
                ViewController.scheduleNotification(category: "_", typeOfN: "notification")
            } else if group.contains("2") {
                ViewController.scheduleNotification(category: "", typeOfN: "reminderBefore")
                ViewController.scheduleNotification(category: "", typeOfN: "reminderAfter")
            }
            
        }
        if doneSetup {
            hideSetup() //Hide the SelectedThing/baseline selection buttons/labels from the main view
        }
    }
    
    func uploadData() {
        // Log this attempt to upload data
        lastFullSyncAttempt = Date()
        let df = DateFormatter()
        df.dateFormat = "hh:mm:ss a"
        let uploadGroup = DispatchGroup()
        //firstSync = true // REMOVE THIS AFTER TESTING... used for debugging
        // Get time difference from last update time
        var ddiff = 1
        if let d = Calendar.current.dateComponents([.minute], from: lastFullSyncDate , to: Date()).minute {
            ddiff = max(d, 30) //takes max of d minutes or 30 minutes.
        }
        // If this is the first update, then collect data from last 30 days.
        if firstSync == true {
            ddiff = 60*24*1 // Collect the last day of data on the first sync
            for (key, _) in syncDate {
                syncDate[key] = Calendar.current.date(byAdding: .minute, value: -ddiff, to: Date())
            }
        }
        
        
        df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        
      
        //ddiff = 60*24*60 USED FOR DEBUGGING
        
        //SYNC baseline and/or SelectedThings
        if syncTypes["Baseline"] == false || syncTypes["SelectedThing"] == false {
            syncStudyCoordinatorWork()
        }
        
       
        //SYNC HealthKit data to server
        var _ : [[String : String]] = [[:]]
        HealthKitData.getSamples(minsAgo: ddiff, endDate: Date()) { result in
            uploadGroup.enter()
            callAPIc(type: "HK", id: studyID, pw: sKey, params: result, onCompletion: { (t) in
                if t[1] == "200"  {
                    print("HealthKit sync successful")
                    syncDate["HK"] = Date()
                    syncTypes["HK"] = true
                    uploadGroup.leave()
                    
                } else {
                    syncTypes["HK"] = false
                    //self.okLabel.text = "Sync error. Try again or contact study coordinator."
                    print("Sync error for HK data, server response \(t[1])")
                    uploadGroup.leave()
                }
            }) { (error) in
                print("Error in uploading healthkit data: \(error)")
                syncTypes["HK"] = false
                uploadGroup.leave()
            }
        }
        
        //SYNC location data to server
        uploadGroup.enter()
      
        callAPIc(type: "Location", id: studyID, pw: sKey, params: locationTimeline, onCompletion: { (lt) in
            if lt[1] == "200" {
       
                syncDate["Location"] = Date()
                syncTypes["Location"] = true
                locationTimeline = [[String : String]]()
                uploadGroup.leave()
            } else {
                syncTypes["Location"] = false
                print("Sync error for Location data, server response \(lt[1])")
                uploadGroup.leave()
            }
            
        }) { (error) in
            print("Error in uploading location data: \(error)")
            syncTypes["Location"] = false
            uploadGroup.leave()
        }
        
        //SYNC Notifications responses to server
        uploadGroup.enter()
        callAPIc(type: "Notification", id: studyID, pw: sKey, params: notificationFeedback, onCompletion: { (nt) in

            if nt[1] == "200"  {
                syncDate["Notification"] = Date()
                syncTypes["Notification"] = true
                var ind = 0
                for n in notificationFeedback {

                    if let temp_date = df.date(from: n["fired_datetime"]!) {
                        if temp_date < Date() {
                            // This is output primarily used for debug purposes.
                            print("*******this notification date was : \(temp_date), which is less than \(Date())")
                            notificationFeedback.remove(at: ind)
                            print("***** Notification \(n) was removed. ")
                        } else {
                            ind += 1
                        }
                    }
                }
                
                notificationFeedback = [[String : String]]() //*** NEEDS TO BE UPDATED
                uploadGroup.leave()
            } else {
                syncTypes["Notification"] = false
              //  print((notificationFeedback))
                print("Sync error for Notification data, server response \(nt[1])")
                uploadGroup.leave()
            }
        }) { (error) in
            print("Error in uploading notification data: \(error)")
            syncTypes["Notification"] = false
            uploadGroup.leave()
        }
        
        //SYNC calendar events
        getCalendarEvents()
        uploadGroup.enter()
        callAPIc(type: "Calendar", id: studyID, pw: sKey, params: calendarEvents, onCompletion: { (ct) in
            if ct[1] == "200"  {
                syncDate["Calendar"] = Date()
                syncTypes["Calendar"] = true
                calendarEvents = [[String : String]]()
                uploadGroup.leave()
            } else {
                syncTypes["Calendar"] = false
                print("Sync error for Calendar data, server response \(ct[1])")
                uploadGroup.leave()
            }
            })  { (error) in
                print("Error in uploading calendar data: \(error)")
                syncTypes["Calendar"] = false
                uploadGroup.leave()
            }

        uploadGroup.enter()
        callAPIc(type: "CMActivity", id: studyID, pw: sKey, params: CMactivityTimeLine, onCompletion: { (ct) in
            if ct[1] == "200"  {
                print("CMActivity sync successful")
                syncDate["CMActivity"] = Date()
                syncTypes["CMActivity"] = true
                CMactivityTimeLine = [[String : String]]()
                uploadGroup.leave()
            } else {
                syncTypes["CMActivity"] = false
                print("Sync error for CMActivity data, server response \(ct[1])")
                uploadGroup.leave()
            }
        })  { (error) in
            print ("CM Activity \(CMactivityTimeLine)")
            print("Error in uploading CMActivity data: \(error)")
            syncTypes["CMActivity"] = false
            uploadGroup.leave()
        }
        uploadGroup.enter()
        callAPIc(type: "CMSteps", id: studyID, pw: sKey, params: CMstepsTimeLine, onCompletion: { (ct) in
            
            if ct[1] == "200"  {
                print("CMSteps sync successful")
                syncDate["CMSteps"] = Date()
                syncTypes["CMSteps"] = true
                CMstepsTimeLine = [[String : String]]()
                uploadGroup.leave()
            } else {
                syncTypes["CMSteps"] = false
                print("Sync error for CMSteps data, server response \(ct[1])")
                uploadGroup.leave()
            }
        })  { (error) in
            print ("CMSteps \(CMstepsTimeLine)")
            print("Error in uploading CMSteps data: \(error)")
            syncTypes["CMSteps"] = false
            uploadGroup.leave()
        }  
        
        //Check if app in background or foreground
        let state: UIApplicationState = UIApplication.shared.applicationState
        var bState = 0
        if state == .active {
            bState = 1
            // foreground
        }
        //Check all reoccuring sync types...if they've synced, update last successful upload time
            uploadGroup.notify(queue: .main) {
                //MODIFIED FOR NEW GROUPS
                if (syncTypes["HK"]! && syncTypes["Calendar"]! && syncTypes["Notification"]! && syncTypes["Location"]!) || (syncTypes["Baseline"]! && group.contains("0")) {
                    if firstSync {
                        firstSync = false
                    }
                    lastFullSyncDate = Date()
                    if bState == 1 {
                        self.lastSyncLabel.text = "Last successful upload: \(df.string(from: lastFullSyncDate))"
                    }
                } else {
                    if bState == 1 {
                        self.lastSyncLabel.text = "Last upload attempt:  \(df.string(from: Date()))"
                    }
                    // Sync didnt' occur. May want to take action here
                }
            }
    }
    
    //Mark calendar access
    func getCalendarEvents() {
        let eventStore = EKEventStore()
        let calendars = eventStore.calendars(for: .event)
        let formatter = DateFormatter()
        // initially set the format based on your datepicker date / server String
        formatter.dateFormat = "MM.dd.yyyy HH:mm:ss"
        for calendar in calendars {
            var predicate = NSPredicate()
            if firstSync {
                // Get events from last two weeks
                predicate = eventStore.predicateForEvents(withStart: Date()-7*60*60*24, end: Date(), calendars: [calendar])
            } else { // Otherwise get events from last sync time
                predicate = eventStore.predicateForEvents(withStart: syncDate["Calendar"]!, end: Date(), calendars: [calendar])
            }
        let events = eventStore.events(matching: predicate)
            for event in events {
                calendarEvents.append(["studyId" : studyID, "name" : "Event", "all_day" :  "\(event.isAllDay)", "start_date" : formatter.string(from: event.startDate), "end_date" : formatter.string(from: event.endDate)])
            }
        }
    }
    
    func loadSteps() {
        if baseline > 0 {
            baselineStepsLabel.isHidden = false
            baselineStepsName.isEnabled = false
            baselineStepsLabel.text = "\(baseline)"
        } else {
            baselineStepsName.isHidden = true
            baselineStepsLabel.isHidden = true
        }

        CoreMotionData.getStepCountFrom(startDate: Date()) { (sc) in
            self.todaysStepsLabel.text = sc
        }
        
        CoreMotionData.getStepCountFrom(startDate: Date() - 60*60*24*7) { (sc) in
            self.weeksStepsLabel.text = String(describing: Int(Double(sc)!/7))
        }
    }
    
    //Mark: viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yyyy"

        // if it's been at least 6 hours since last sync, then sync again
        if let c = Calendar.current.dateComponents([.hour], from: lastFullSyncDate , to: Date()).hour {
            if  c >= min_sync_time {
                uploadData()
            }
        }
        
        // print("\(lastFullSyncDate)") // Used for Debug
        
        if showNow == true {
            if (group.contains("1") || group.contains("2")) {
                SelectedThingLabel.isHidden = false
                
                SelectedThingButton.isHidden = false
            }
            setBaselineButton.isHidden = false
            okButton.isHidden = false
            okLabel.isHidden = false
            okButton.isEnabled = true
        }
        
        else if doneSetup {
                // If they are done setting a baseline and/or choosing a SelectedThing, hide those buttons and labels from the main screen.
                //SelectedThingLabel.isHidden = true
                SelectedThingButton.isHidden = true
                setBaselineButton.isHidden = true
                okButton.isHidden = true
                okLabel.isHidden = true
        }
    }
    
    //MARK: Location functions
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedAlways {
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
                if CLLocationManager.isRangingAvailable() {
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //Get location data before changing screens or app goes to background
        //locationManager.startUpdatingLocation()
        //locationManager.stopUpdatingLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let locationManager = LocationManager.main_manager
        if firstSync == true {
            locationManager.requestAlwaysAuthorization()
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.pausesLocationUpdatesAutomatically = false
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        } else {
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // this function is called when the locationmanager is instantiated. It appends some location data to the locationTimeLine.
        let latestLocation: CLLocation = locations[locations.count - 1]
        var ddiff = 0
        if let tempDate = locationTimeline.last {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
            if let d = tempDate["Date"] {
                if let dateFromString = dateFormatter.date(from: d) {
                    if let d = Calendar.current.dateComponents([.minute], from: dateFromString, to: latestLocation.timestamp).minute {
                        ddiff = d
                    }
                }
            }
        } else {
            if locationTimeline.count == 0 {
                ddiff = 10
            }
            
        }

        if ddiff >= locationUpdateFrequency{ //If more than 10 minutes has passed since the last recorded location
            locationTimeline.append(["studyId" : studyID, "Date" : "\(Date())", "latitude" : "\(String(format: "%.4f", latestLocation.coordinate.latitude))", "longitude" : "\(String(format: "%.4f", latestLocation.coordinate.longitude))", "h_acc" : "\(String(format: "%.4f", latestLocation.horizontalAccuracy))", "alt" : "\(String(format: "%.4f", latestLocation.altitude))", "v_acc" : "\(String(format: "%.4f", latestLocation.verticalAccuracy))"])
            
            //if app is active can do something here. Otherwise, do something else. Not used
            if UIApplication.shared.applicationState == .active {
                ()
            } else {
                ()
            }
        }
        
    }

    override func viewDidLoad() {
        
        if (group.contains("0") || group.contains("1")) && (doneSetup) {
            // schedule a new group of notifications, if notification count is below 30
            if notificationFeedback.count <= 30 {
                notifications.scheduleNotification(type: "notification", notificationDays: 3)
                dfStore.set(notificationFeedback, forKey: "notificationFeedback")
            }
        }
        
        if (group.contains("2") && doneSetup ) {
            if let timeDiff = Calendar.current.dateComponents([.day], from: consentDate, to: Date()).day {
                if Double(timeDiff)/7.0 >= 0 && timeDiff > 1 { // If a week after baseline period, and setup is completed.
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests() // Clear previous notifications (if any)
                    ViewController.scheduleNotification(category: "", typeOfN: "reminderBefore")
                    ViewController.scheduleNotification(category: "", typeOfN: "reminderAfter")
                }
            }
            
        }
    
        loadSteps()
        syncTypes["Profile"] = true
        CoreMotionData.getCMData(from: syncDate["CMActivity"]!)
        
        let eventStore = EKEventStore()
        eventStore.requestAccess(to: EKEntityType.event, completion: {(granted, error) in
            if !granted {
                print("Access to eventkit store not granted")
            }
        })
        studyIDLabel.text = ("My Study ID is: \(studyID)")
        //Get notificaiton center ready
        notifications.configureUserNotificationCenter()
        // Update last sync
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        lastSyncLabel.text = "Last upload on: \(df.string(from: lastFullSyncDate))"
        // Change button labels if consent granted
       
        if doneSetup == false {
            if SelectedThing != "" && SelectedThingSelected == true && group != "Control" {
                //SelectedThingButton.isEnabled = false
                SelectedThingButton.setTitle("✅ SelectedThing selected", for: UIControlState.normal)
                let dateFormatterPrint = DateFormatter()
                dateFormatterPrint.dateFormat = "hh:mm a"
                SelectedThingLabel.isHidden = false
                SelectedThingLabel.text = "Your SelectedThing is: \"\(SelectedThing)\" at \(dateFormatterPrint.string(from: SelectedThingTime))."
            }
            if baseline > 0 {
                print("viewload \(baseline)")
                setBaselineButton.setTitle("✅ Baseline selected ", for: UIControlState.normal)
            
                if ((SelectedThingSelected == true && (group.contains("1") || group.contains("2"))) || group.contains("0")) {
                    okButton.isEnabled = true
                    okButton.setTitle("👉 Ok, I'm Done", for: UIControlState.normal)
                } else {
                    okButton.isEnabled = false
                    okButton.setTitle("Ok, I'm Done", for: UIControlState.disabled)
                }
            }
        } else if doneSetup == true {
            hideSetup()
        }
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    class func scheduleNotification(category: String, typeOfN: String) {
        // Request Notification Settings
        UNUserNotificationCenter.current().getNotificationSettings { (notificationSettings) in
            switch notificationSettings.authorizationStatus {
            case .notDetermined:
                notifications.requestAuthorization(completionHandler: { (success) in
                    guard success else { return }
                    // Try to schedule notifications...
                    notifications.scheduleNotification(type: typeOfN, notificationDays: 1)
                })
            case .authorized:
                // Schedule a notification
           
                notifications.scheduleNotification(type: typeOfN, notificationDays: 1)
            case .denied:
                print("Notification permission denied.")
            case .provisional:
                // Schedule Local Notification
                notifications.scheduleNotification(type: typeOfN, notificationDays: 1)
            }
        }
    }

    func hideSetup() {
        // Get rid of UI element that involve setup
        setBaselineButton.isEnabled = false
        setBaselineButton.isHidden = true
        SelectedThingButton.isEnabled = false
        SelectedThingButton.isHidden = true
        if SelectedThing != "" && SelectedThingSelected == true && group != "Control" {
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "hh:mm a"
            SelectedThingLabel.isHidden = false
            SelectedThingLabel.text = "Your SelectedThing is: \"\(SelectedThing)\" at \(dateFormatterPrint.string(from: SelectedThingTime))."
        }
        okButton.isHidden = true
        okLabel.isHidden = true
    }
}
