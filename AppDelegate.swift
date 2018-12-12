 //Copyright © 2018 IBM.

import UIKit
import ResearchKit
import UserNotifications
import CoreLocation
import PDFKit
import CSVImporter
import SwiftNotes

 // Data management should ideally be done with a SQLlite db. This was done as a quick and messy proto-typing and needs to be refactored and improved upon in later builds.
 
let notifications = NotificationController()
let healthKitMan = HealthKitManager() // This will be the instance of HealthKit to be accessed from the main screen
let dfStore = UserDefaults.standard

public let min_sync_time = 6
public var numNotifications = 20
public var notificationsPerDay = 6
public var firstSync = true
public var consentDate = Date()
public var consentSigned = false
public var hkAllowed = false
public var SelectedThingSelected = false
public var timeSinceLastNotification = 0.0
public var SelectedThing = ""
public var SelectedThingTime = Date()//[0,0]
public var SelectedThingDetails : [String : String] = ["":""]

public var notificationsEnabled = false
public var locationEnabled = false
public var baseline = -1
public var studyID = "Not yet set."
public var uuid = UIDevice.current.identifierForVendor?.uuidString
public var group = "" // Control, Treatment0, Treatment1, Treatment2 are valid values for group
public var sKey  = ""
public let apiID = "test_id_here"
public let apiPW = "test_pw_here"
public var doneSetup = false
public var hkSyncDate = Date()
public var syncDate : [String : Date] = [:]

public var syncTypes : [String : Bool] = [:]
public var locationTimeline : [[String: String]] = [[:]] //
public var CMactivityTimeLine : [[String: String]] = [[:]] //
public var CMstepsTimeLine : [[String: String]] = [[:]] //
public var notificationFeedback : [[String: String]] = [[:]] // Format is [timestamp, notification_ID, feedback_ID
public var notificationList : [String : String] = [:] // List of all notifications sent
public var notificationsLibrary : [String] = []// Library of notifications to choose from when sending a notification
public var CuesSet : [String] = []

public var CuesBehaviorsMapping : [String : [String]] = ["" : [""]]
public var calendarEvents : [[String : String]] = [[:]]
public var lastFullSyncDate = Date()
public var lastFullSyncAttempt = Date()
public var notification_counter = 0
public var studyEndDate = "12/30/2018" 
public var locationUpdateFrequency = 10 //update location every 10 minuates (at the most)

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate {
    let locationManager = LocationManager.main_manager

    var window: UIWindow?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
    
    func loadDefaults (onCompleted: @escaping () -> () ) {
       
        loadVars()
        /*let dgroup = DispatchGroup()
        dgroup.enter()*/
        
        readCSVs( onCompleted: {
            onCompleted()
        })
        
    }
    
    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
         // Pause for launch screen load
        sleep(1)
        UNUserNotificationCenter.current().delegate = self
        // Load UserDefaults
        loadDefaults( onCompleted: {
            print("default values loaded")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            let studyEnd = dateFormatter.date(from: studyEndDate)!
            if Date() >= studyEnd {
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let cont: UIViewController = storyboard.instantiateViewController(withIdentifier: "EndViewController")
                self.window?.makeKeyAndVisible()
                self.window?.rootViewController = cont
            } else if (studyID == "" || hkAllowed == false || notificationsEnabled == false || syncTypes["Profile"] == false) {
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let cont: UIViewController     = storyboard.instantiateViewController(withIdentifier: "SetupViewController")
                self.window?.makeKeyAndVisible()
                self.window?.rootViewController = cont
            } else {
                let remoteNotif = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? NSDictionary
                if remoteNotif != nil {
                    let aps = remoteNotif!["aps" as NSString] as? [String:AnyObject]
                    print("\n Custom: \(String(describing: aps))")
                }
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                let cont: UIViewController = storyboard.instantiateViewController(withIdentifier: "ViewController")
                self.window?.makeKeyAndVisible()
                self.window?.rootViewController = cont
            }
        })
            
            // Set minimum fetch interval...30 minutes for test
            UIApplication.shared.setMinimumBackgroundFetchInterval(30)
            
            //Initialize the location manager
            
            if firstSync == false {
                locationManager.requestAlwaysAuthorization()
                locationManager.allowsBackgroundLocationUpdates = true
                locationManager.delegate = self
                locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                locationManager.pausesLocationUpdatesAutomatically = false
                locationManager.startUpdatingLocation()
                locationManager.startMonitoringSignificantLocationChanges()
            }
            // Need to set delegate to self to handle actionable local notifications
            UNUserNotificationCenter.current().delegate = self

        return true
    }

    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {

        // This function handles notification responses
        notificationAutoSchedule()
        switch identifier! {
        case "Good":
            print("Good")
        case "Bad timing":
            print("Bad time feedback")
        case "Bad":
            print("Bad")
        case "Did it":
            print("Did it")
        case "Forgot":
            print("Forgot")
        case "Could not":
            print("Could not")
        case "Didn't feel like it":
            print("Didn't feel like it")
        case UNNotificationDismissActionIdentifier:
            print("Dismissed")
        default:
            print("Ok")
        }
        
        let df = DateFormatter()
            df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        var notif_of_interest = 0
        var found_it = false
        findnotification: for n in notificationFeedback {
            if let fdate = n["fired_datetime"] {
                if fdate == df.string(from: notification.fireDate!) {
                    found_it = true
                    break findnotification
                } else {
                    notif_of_interest += 1
                    
                }
                
            }
        }
        
        if found_it {
            print("before update... \(notificationFeedback[notif_of_interest])")
            notificationFeedback[notif_of_interest].updateValue(df.string(from: Date()), forKey: "response_datetime")
            notificationFeedback[notif_of_interest].updateValue(String(describing: identifier!), forKey: "response")
            print("after update... \(notificationFeedback[notif_of_interest])")
        } else {
            
            notificationFeedback.append(["studyId" : studyID ,"fired_datetime" : df.string(from: notification.fireDate!), "fired_notification_id" :  "delayed_response", "response_datetime" : df.string(from: Date()), "notification_id" : "\(String(describing: notification.category))", "response" : "\(String(describing: identifier!))"]) //, "notification_status" : "responded")
        }
   
        completionHandler()
    }
  
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // fetch data from internet now

        print("Background refresh occured")
        //MODIFIED FOR NEW GROUPS
        notificationAutoSchedule()
        
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yyyy"
        // if it's been at least min_sync_time hours since last sync, then sync again.
        if let c = Calendar.current.dateComponents([.hour], from: lastFullSyncAttempt , to: Date()).hour {
            if  c >= min_sync_time {
                CoreMotionData.getCMData(from: syncDate["CMActivity"]! - 100)
                ViewController().uploadData()

            } else {
                ()
            }
        }
        
        completionHandler(.noData)
    }
  
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.

        saveVars()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        saveVars()
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
       
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        saveVars()
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
            
         
            // If you want to do some logic based on the application being active or in the background, you can do it here.
            if UIApplication.shared.applicationState == .active {
                ()
            } else {
                ()
            }
        }
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    func notificationAutoSchedule() {
        if ((group.contains("0") || group.contains("1")) && (doneSetup)) {
            // Schedule BCE notifications if few remain
            if notificationFeedback.count <= 30 {
                notifications.scheduleNotification(type: "notification", notificationDays: 3)
                dfStore.set(notificationFeedback, forKey: "notificationFeedback")
            }
        }
        
        if (group.contains("2") && doneSetup ) {
            if let timeDiff = Calendar.current.dateComponents([.day], from: consentDate, to: Date()).day {
                if timeDiff % 7 == 0 && timeDiff > 1{ //(true) { //for testing
                    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                    ViewController.scheduleNotification(category: "", typeOfN: "reminderBefore")
                    ViewController.scheduleNotification(category: "", typeOfN: "reminderAfter")
            
                }
            }
            
        }
        
    }
    
    func saveVars() {
        dfStore.set(firstSync, forKey: "firstSync")
        dfStore.set(consentSigned, forKey: "consentSigned")
        dfStore.set(consentDate, forKey: "consentDate")
        dfStore.set(lastFullSyncDate, forKey: "lastFullSyncDate")
        dfStore.set(lastFullSyncAttempt, forKey: "lastFullSyncAttempt")
        dfStore.set(hkAllowed, forKey: "hkAllowed")
        dfStore.set(SelectedThingSelected, forKey: "SelectedThingSelected")
        dfStore.set(SelectedThing, forKey: "SelectedThing")
        dfStore.set(SelectedThingTime, forKey: "SelectedThingTime")
        dfStore.set(SelectedThingDetails, forKey: "SelectedThingDetails")
        //dfStore.set(SelectedThingNotesEntry, forKey: "SelectedThingNotesEntry")
        dfStore.set(notificationsEnabled, forKey: "notificationsEnabled")
        dfStore.set(locationEnabled, forKey: "locationEnabled")
        dfStore.set(baseline, forKey: "baseline")
        dfStore.set(group, forKey: "group")
        dfStore.set(studyID, forKey: "studyID")
        dfStore.set(sKey, forKey: "sKey")
        dfStore.set(doneSetup, forKey: "doneSetup")
        dfStore.set(notificationFeedback, forKey: "notificationFeedback")
        dfStore.set(CMactivityTimeLine, forKey: "CMactivityTimeLine")
        dfStore.set(CMstepsTimeLine, forKey: "CMstepsTimeLine")
        dfStore.set(locationTimeline, forKey: "locationTimeline")
        dfStore.set(calendarEvents, forKey: "calendarEvents")
        dfStore.set(syncDate["Profile"], forKey: "profileSyncDate")
        dfStore.set(syncDate["Location"], forKey: "locationSyncDate")
        dfStore.set(syncDate["SelectedThing"], forKey: "SelectedThingSyncDate")
        dfStore.set(syncDate["Baseline"], forKey: "baselineSyncDate")
        dfStore.set(syncDate["Notification"], forKey: "responseSyncDate")
        dfStore.set(syncDate["HK"], forKey: "hkSyncDate")
        dfStore.set(syncDate["Calendar"], forKey: "calendarSyncDate")
        dfStore.set(syncDate["CMActivity"], forKey: "CMActivtiy")
        dfStore.set(syncDate["CMSteps"], forKey: "CMSteps")
        dfStore.set(syncTypes["Calendar"], forKey: "syncCalendar")
        dfStore.set(syncTypes["Profile"], forKey: "syncProfile")
        dfStore.set(syncTypes["Location"], forKey: "syncLocation")
        dfStore.set(syncTypes["SelectedThing"], forKey: "syncSelectedThing")
        dfStore.set(syncTypes["Baseline"], forKey: "syncBaseline")
        dfStore.set(syncTypes["Notification"], forKey: "syncResponse")
        dfStore.set(syncTypes["HK"], forKey: "syncHK")
        dfStore.set(syncTypes["notification_counter"], forKey: "notification_counter")
    }
    
    func loadVars() {
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yyyy"
        firstSync = dfStore.object(forKey: "firstUpdate") as? Bool ?? true // Load status whether HealthKit access is allowed
        hkAllowed = dfStore.object(forKey: "hkAllowed") as? Bool ?? Bool() // Load status whether HealthKit access is allowed
        consentSigned = dfStore.object(forKey: "consentSigned") as? Bool ?? Bool() // Load status whether consent is signed
        consentDate = dfStore.object(forKey: "consentDate") as? Date ?? Date() // Load date that consent is signed
        lastFullSyncDate = dfStore.object(forKey: "lastFullSyncDate") as? Date ?? Date() // Load date that consent is signed
        lastFullSyncAttempt = dfStore.object(forKey: "lastFullSyncAttempt") as? Date ?? Date() // Load date that consent is signed
        SelectedThingSelected = dfStore.object(forKey: "SelectedThingSelected") as? Bool ?? Bool() // Load status whether a SelectedThing is selected
        SelectedThing = dfStore.object(forKey: "SelectedThing") as? String ?? String() // Load status whether a SelectedThing is selected
        SelectedThingTime = dfStore.object(forKey: "SelectedThingTime") as? Date ?? Date() // Load status whether a SelectedThing time is specified
        SelectedThingDetails = dfStore.object(forKey: "SelectedThingDetails") as? [String:String] ?? [String:String]() // Load details of the SelectedThing
        notificationsEnabled = dfStore.object(forKey: "notificationsEnabled") as? Bool ?? Bool() // Load status whether a notification is allowed
        locationEnabled = dfStore.object(forKey: "locationEnabled") as? Bool ?? Bool() // Load status whether access to location is allowed
        doneSetup = dfStore.object(forKey: "doneSetup") as? Bool ?? Bool() // Load done setup status (baseline/SelectedThing)
        baseline = dfStore.object(forKey: "baseline") as? Int ?? Int() // Load status whether a SelectedThing time is specified
        group = dfStore.object(forKey: "group") as? String ?? String() // Load status whether a SelectedThing time is specified
        studyID = dfStore.object(forKey: "studyID") as? String ?? String() // Load status whether a SelectedThing time is specified
        sKey = dfStore.object(forKey: "sKey") as? String ?? String() // Load status whether a SelectedThing time is specified
        notificationFeedback = dfStore.object(forKey: "notificationFeedback") as? [[String:String]] ?? [[String:String]]() // Load status whether a SelectedThing time is specified
        locationTimeline = dfStore.object(forKey: "locationTimeline") as? [[String:String]] ?? [[String:String]]() // Load status whether a SelectedThing time is specified
        CMactivityTimeLine = dfStore.object(forKey: "CMactivityTimeLine") as? [[String:String]] ?? [[String:String]]()
        CMstepsTimeLine = dfStore.object(forKey: "CMstepsTimeLine") as? [[String:String]] ?? [[String:String]]()
        calendarEvents = dfStore.object(forKey: "calendarEvents") as? [[String:String]] ?? [[String:String]]() // Load status whether a SelectedThing time is specified
        notification_counter = dfStore.object(forKey: "notification_counter") as? Int ?? Int()
        syncTypes["HK"] = dfStore.object(forKey: "syncHK") as? Bool ?? Bool()
        syncTypes["Location"] = dfStore.object(forKey: "syncLocation") as? Bool ?? Bool()
        syncTypes["Profile"] = dfStore.object(forKey: "syncProfile") as? Bool ?? Bool()
        syncTypes["SelectedThing"] = dfStore.object(forKey: "syncSelectedThing") as? Bool ?? Bool()
        syncTypes["Baseline"] = dfStore.object(forKey: "syncBaseline") as? Bool ?? Bool()
        syncTypes["Notification"] = dfStore.object(forKey: "syncResponse") as? Bool ?? Bool()
        syncTypes["Calendar"] = dfStore.object(forKey: "syncCalendar") as? Bool ?? Bool()
        syncTypes["CMSteps"] = dfStore.object(forKey: "CMSteps") as? Bool ?? Bool()
        syncTypes["CMActivity"] = dfStore.object(forKey: "CMActivity") as? Bool ?? Bool()
        
        // Example notifications
        notificationList["id1"] =  "Test notification 1"
        notificationList["id2"] =  "Test notification 2"
        notificationList["id3"] =  "Test notification 3"
        
        if firstSync {
            syncDate["HK"] = Date()
            syncDate["Location"] = Date()
            syncDate["Profile"] = Date()
            syncDate["SelectedThing"] = Date()
            syncDate["Baseline"] = Date()
            syncDate["Notification"] = Date()
            syncDate["Calendar"] = Date()
            syncDate["CMSteps"] = Date()
            syncDate["CMActivity"] = Date()
            lastFullSyncDate = Date()
            lastFullSyncAttempt = Date()
        } else {
            syncDate["HK"] = dfStore.object(forKey: "locationSyncDate") as? Date ?? Date() // Load last update date
            syncDate["Location"] = dfStore.object(forKey: "locationSyncDate") as? Date ?? Date() // Load last update date
            syncDate["Profile"] = dfStore.object(forKey: "profileSyncDate") as? Date ?? Date() // Load status whether a SelectedThing time is specified
            syncDate["SelectedThing"] = dfStore.object(forKey: "SelectedThingSyncDate") as? Date ?? Date() // Load status whether a SelectedThing time is specified
            syncDate["Baseline"] = dfStore.object(forKey: "baselineSyncDate") as? Date ?? Date() // Load status whether a SelectedThing time is specified
            syncDate["Notification"] = dfStore.object(forKey: "responseSyncDate") as? Date ?? Date() // Load status whether a SelectedThing time is specified
            syncDate["Calendar"] = dfStore.object(forKey: "calendarSyncDate") as? Date ?? Date() // Load status whether a SelectedThing time is specified
            syncDate["CMActivity"] = dfStore.object(forKey: "CMActivity") as? Date ?? Date() // Load status whether a SelectedThing time is specified
            syncDate["CMSteps"] = dfStore.object(forKey: "CMSteps") as? Date ?? Date() // Load status whether a SelectedThing time is specified
        }
    }
    
    func readCSVs(onCompleted: @escaping () -> () ) {
        let path0 = Bundle.main.path(forResource: "list_of_notifications_here", ofType: "csv")
        let importer0 = CSVImporter<[String]>(path: path0!)
        
        importer0.startImportingRecords { $0 }.onFinish { importedRecords in
            for record in importedRecords {
             
                notificationsLibrary.append(record[0])
                // record is of type [String] and contains all data in a line
            }
            onCompleted()
        
        }
        
        let path1 = Bundle.main.path(forResource: "cues_file_here", ofType: "csv")
        let importer1 = CSVImporter<[String]>(path: path1!, delimiter: ",")
        importer1.startImportingRecords { $0 }.onFinish { importedRecords in
            for record in importedRecords {
                //CuesSet[record[0]] = record[1]
                CuesSet.append(record[1])
                // record is of type [String] and contains all data in a line
            }
            print(CuesSet)
        }
       
        
        let path2 = Bundle.main.path(forResource: "mapping_file_here", ofType: "txt")
        let importer2 = CSVImporter<[String]>(path: path2!, delimiter: ";")
        
        importer2.startImportingRecords { $0 }.onFinish { importedRecords in
            for record in importedRecords {
                var temp_array : [String] = []
                for i in 2...record.count - 1 {
                    temp_array.append(record[i])
                }
                CuesBehaviorsMapping[record[1]] = [String]() //"cue"] = record[1]
                CuesBehaviorsMapping[record[1]]! = temp_array
            }
            print(CuesBehaviorsMapping)
        }
        
    }
}

extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
   
}
