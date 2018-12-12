// Copyright © 2018 IBM.

import Foundation
import UserNotifications
let numDaysOfNotifications = 10
class NotificationController: NSObject{

    class func listPendingNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { requests in
            for request in requests {
                print(request)
            }
        })
    }

    class func listDeliveredNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { (requests) in
        })
    }
    
    func configureUserNotificationCenter() {
        // Configure User Notification Center
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        
        //Define actions
        let actionGood = UNNotificationAction(identifier: Notification.Action.good, title: "Good.", options: [])
        let actionBad = UNNotificationAction(identifier: Notification.Action.bad, title: "Bad.", options: [])
        let actionOk = UNNotificationAction(identifier: Notification.Action.ok, title: "Ok.", options: [])
        let actionBadTime = UNNotificationAction(identifier: Notification.Action.badTime, title: "Bad timing", options: [])
        
        let rActionDidIt = UNNotificationAction(identifier: Notification.Action.rDidIt, title: "I did it.", options: [])
        let rActionForgot = UNNotificationAction(identifier: Notification.Action.rForgot, title: "I forgot;", options: [])
        let rActionCouldNot = UNNotificationAction(identifier: Notification.Action.rCouldNot, title: "No can do.", options: [])
        let rActionFeelNot = UNNotificationAction(identifier: Notification.Action.rFeel, title: "I didn't feel like it.", options: [])
        //let actionNone = UNNotificationAction(identifier: Notification.Action.none, title: "", options: [])
        
        var notification_placeholder = [String]()
        notification_placeholder.append("id: notification1")
        notification_placeholder.append("id: reminder1")
        
        // Define category. Each id for notification, nudge will be a differnet category
        let notificationCategory = UNNotificationCategory(identifier: Notification.category.notification, actions: [actionGood, actionOk, actionBad, actionBadTime ], intentIdentifiers: [], options: [])
        
        let reminderBeforeCategory = UNNotificationCategory(identifier: Notification.category.reminderBefore, actions: [], intentIdentifiers: [], options: [])
        
        let reminderAfterCategory = UNNotificationCategory(identifier: Notification.category.reminderAfter, actions: [rActionDidIt, rActionForgot, rActionCouldNot, rActionFeelNot ], intentIdentifiers: [], options: [])
        
        // Register Category
        UNUserNotificationCenter.current().setNotificationCategories([notificationCategory, reminderBeforeCategory, reminderAfterCategory])
    }
    
    func requestAuthorization(completionHandler: @escaping (_ success: Bool) -> ()) {
        // Request Authorization
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            if let error = error {
                print("Notification Request Authorization Failed (\(error), \(error.localizedDescription))")
            }
            completionHandler(success)
        }
    }
    
    public struct Notification {
        
        struct category {
            // Three types of categories: notifications, reminders before the SelectedThing time, and reminders after the SelectedThing time.
            static let notification = "notification"
            static let reminderBefore = "reminderBefore"
            static let reminderAfter = "reminderAfter"
        }
        
        struct Action {
            
            // Actions for informational notifications
            static let good = "Good"
            static let bad = "Bad"
            static let ok = "Ok"
            static let badTime = "Bad timing"
            
            // Actions for reminders
            static let rDidIt = "Did it"
            static let rForgot = "Forgot"
            static let rCouldNot = "Could not"
            static let rFeel = "Didn't feel like it"
        }
        
        struct fired_id {
            static var id = "idhere" //update notification id here
        }
    }
    
    func scheduleNotification(type: String, notificationDays: Int) {
        let notificationContent = UNMutableNotificationContent()
        let calendar = Calendar.current
        print("Notifications scheduled for type: \(type) and for this many days: \(notificationDays)")

       
       // default case is a test notification.
        notification_counter += 1
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        
        // You can define several types of notifications to be processed.
        
        if type == "notification" {
   
            // Set category identifier
            notificationContent.categoryIdentifier = Notification.category.notification
            //notificationContent.setValue("YES", forKey: "shouldAlwaysAlertWhileAppIsForeground")
            
            // Add temp trigger
           // let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 9.0, repeats: false)
           
            //generate times for the notifications. Default setting is between 8am and 10pm.
            for d in 0...notificationDays - 1 {
                var times : [[Int]] = []
                times.append([10 + Int(arc4random_uniform(UInt32(3))) - 1, Int(arc4random_uniform(UInt32(60)))])

                let nPerDay = Int(Double(arc4random_uniform(3))) + 3
                
                // Get last notification time from notification list...
                var date_of_last_notif = Date() - 100*60*60*24
                if notificationFeedback.count > 1 {
                    for n in notificationFeedback {
                        if let temp_date = n["fired_datetime"] {
                            if let tdate = df.date(from: temp_date) {
                                if n["fired_notification_id"]?.contains("_test_") != true {
                                    if tdate <= Date() {
                                        print("****found a later date in the NotificaitonList \(n)")
                                        
                                        date_of_last_notif = df.date(from: n["fired_datetime"]!)!
                                        date_of_last_notif = calendar.date(byAdding: .day, value: 1, to: date_of_last_notif)!
                                    }
                                }
                            }
                        }
                      
                    }
                }
                
                //If date_of_last_notification is still set to the really old date (10 days old), then scehdule notifications to start today. OTherwise, it will schedule notifications for one day after the latest notification scheduled in the list.
                if date_of_last_notif <= Date() - 10*60*60*24 {
                    date_of_last_notif = Date()
                }
                
                for i in 1...nPerDay {
                                     
                    // Choose a notification messsage at random from the Notificaitons Library
                    let ntype =  max(Int(Double(arc4random_uniform(UInt32(notificationsLibrary.count)))) - 1,0)
                    notificationContent.body = notificationsLibrary[ntype]
                
                    // Get a random notification text body
                    let j : Int = Int(arc4random_uniform(UInt32(notificationList.count)))
                    let nID = Array(notificationList.keys)[j]
                    let nText = notificationList[nID]
                    // Assign a random time for the notification)
                    
                    let dateTracker = calendar.date(byAdding: .day, value: d, to: date_of_last_notif)
                    let hour = max(times[i-1][0]+1, (10 + (i * 2) + Int(arc4random_uniform(UInt32(3)))) - 1)
                    let minutes = Int(arc4random_uniform(UInt32(60)))
                    var t = DateComponents()
                    t.hour = hour
                    t.minute = minutes
                    t.day = calendar.component(.day, from: dateTracker!)
                    t.month = calendar.component(.month, from: dateTracker!)
                    t.year = calendar.component(.year, from: dateTracker!)
                    var tLastN = DateComponents()
                    tLastN.hour = times[i-1][0]
                    tLastN.minute = times[i-1][1]
                    
                    // No notifications can be within 60 minutes of each other
                    let time_between_notifications = 60
                    if let timeDiff = Calendar.current.dateComponents([.minute], from: t, to: tLastN).minute {
                        if timeDiff <= time_between_notifications && timeDiff >= -1 * time_between_notifications {
                            t.minute = t.minute! + min(59, 60 - abs(timeDiff))
                        }
                    }
                    // Add time to time list
                    times.append([t.hour!, t.minute!])
                    
                    // Schedule notifications
                    let trigger = UNCalendarNotificationTrigger(dateMatching: t, repeats: false)
                    //notificationContent.subtitle = "bce_local_notification_\(d)_\(i)" //  For debug
                    let notificationRequest = UNNotificationRequest(identifier: "bce_local_notification_\(d)_\(i)", content: notificationContent, trigger: trigger)
                   // print("Notification: \(notificationList[nID]!) scheduled for \(t)") //
                    UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                        if let error = error {
                            print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
                        }
                    }
                    
                    let df = DateFormatter()
                    df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
                    let notifid = String(ntype)
  
                    var fdate = " "
                    if let fd = trigger.nextTriggerDate() {
                        fdate = df.string(from: fd)
                    }

                    notificationFeedback.append(["studyId" : studyID ,"fired_datetime" : fdate, "response_datetime" : "not_yet", "fired_notification_id" : notificationRequest.identifier, "notification_id" : notifid, "response" : "not_yet"])
                    
                }
            }
            
        } else if type == "reminderBefore" {
            //logic for the BEFORE SelectedThing reminders goes here. This redminer is for 30 minutes BEFORE the selected SelectedThing time.
            
            let u = Double(arc4random()) / Double(UInt32.max)
            if u <= 0.33 {
                notificationContent.body = "Don't forget your SelectedThing \(SelectedThing)"
            } else if u > 0.33 && u <= 0.66 {
                notificationContent.body = "Remember, you chose \(SelectedThing) as something you'll try to do!"
                
            } else {
                notificationContent.body = "Hey, just a reminder that you've got this SelectedThing coming up... \(SelectedThing)"
            }
            
            // Set category identifier
            notificationContent.categoryIdentifier = Notification.category.reminderBefore
           
            // schedule reminder 30 minutes before
            var d = DateComponents()
            let calendar = Calendar.current
            
            let before_time = -1 * randomReminderTime()
           
            let tempHT = calendar.date(byAdding: .minute, value: before_time, to: SelectedThingTime)!
            print("\(tempHT)")
            d.hour = calendar.component(.hour, from: tempHT)//SelectedThingTime[0]
            d.minute = calendar.component(.minute, from: tempHT)//SelectedThingTime[1]
            if (d.hour! == 7 && d.minute! <= 0) || d.hour! < 7 { // No notificaitons before 7am. Schedule earlier notificaitons for 6pm the previous evening.
                d.hour = 18
                d.minute = 0
            } else {
                // Schedule notification at planned time
            }
            let trigger = UNCalendarNotificationTrigger(dateMatching: d, repeats: true)
            let notificationRequest = UNNotificationRequest(identifier: "bce_local_reminderBefore", content: notificationContent, trigger: trigger)
            print("Notification: \(type) scheduled for \(d.hour) \(d.minute)")
            
            UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                if let error = error {
                    print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
                }
            }
            let df = DateFormatter()
            df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
            let notifid = type //(String(describing: notificationRequest.identifier) + "_type_\(ntype)")
           
            var fdate = " "
            if let fd = trigger.nextTriggerDate() {
                fdate = df.string(from: fd)
            }
            
            notificationFeedback.append(["studyId" : studyID ,"fired_datetime" : fdate, "response_datetime" : "not_yet", "fired_notification_id" : notificationRequest.identifier, "notification_id" : type, "response" : "not_yet"])
            
        } else if type == "reminderAfter" {
            //logic for the AFTER SelectedThing reminder goes here. This redminer is for 30 minutes AFTER the selected SelectedThing time.
            
            // Placeholder for reminder language
            
            let u = Double(arc4random()) / Double(UInt32.max)
            if u <= 0.33 {
                 notificationContent.body = "Hey, did you perform the SelectedThing today? \(SelectedThing)?"
            } else if u > 0.33 && u <= 0.66 {
                notificationContent.body = "Did you remember to perform your chosen SelectedThing today?"

            } else {
                notificationContent.body = "You were supposed to do this SelectedThing today: \(SelectedThing)... How did it go?"
            }
            
            // Set category identifier
            notificationContent.categoryIdentifier = Notification.category.reminderAfter
           
            // schedule reminder 30 minutes before
            var d = DateComponents()
            let calendar = Calendar.current
            
            let after_time = randomReminderTime()
            let tempHT = calendar.date(byAdding: .minute, value: after_time, to: SelectedThingTime)!
            
            d.hour = calendar.component(.hour, from: tempHT)//SelectedThingTime[0]
            d.minute = calendar.component(.minute, from: tempHT)//SelectedThingTime[1]
            let trigger = UNCalendarNotificationTrigger(dateMatching: d, repeats: true)
            let notificationRequest = UNNotificationRequest(identifier: "bce_local_reminderAfter", content: notificationContent, trigger: trigger)
            print("Notification: \(type) scheduled for \(String(describing: d.hour)) \(String(describing: d.minute))")
            UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                if let error = error {
                    print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
                }
            }
            let df = DateFormatter()
            df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
            
            var fdate = " "
            if let fd = trigger.nextTriggerDate() {
                fdate = df.string(from: fd)
            }

            let notifid = type //(String(describing: notificationRequest.identifier) + "_type_\(ntype)")
            //[["fired_notification_id": "bce_0_1", "notification_id": "2", "studyId": "777", "response": "not_yet", "response_datetime": "not_yet", "fired_datetime": " "]
            notificationFeedback.append(["studyId" : studyID ,"fired_datetime" : fdate, "response_datetime" : "not_yet", "fired_notification_id" : notificationRequest.identifier, "notification_id" : type, "response" : "not_yet"])
        } else if type == "test"{
            //This is the old way of testing for notifications, randomly selecting from one of three notifications...
            
            /* let u = Double(arc4random()) / Double(UInt32.max)
            if u <= 0.33 {
                notificationContent.body = "Nudge nudge nudge ... I'm starting to hate the word nudge."
            } else if u > 0.33 && u <= 0.66 {
                notificationContent.body = "Nudge nudge nudge ... I kinda like that word... \"nudge\"..."
            } else {
                notificationContent.body = "...time for a nudge..."
            } */
            
            //let u = Double(arc4random()) / Double(UInt32.max)
            
            // Choose a notification messsage at random from the Notifications Library
            let ntype = Int(Double(arc4random_uniform(UInt32(notificationsLibrary.count)))) - 1
            notificationContent.body = notificationsLibrary[ntype]
         
          
            // Set category identifier
            notificationContent.categoryIdentifier = Notification.category.notification
            
            // Add a temporary trigger
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10.0, repeats: false)
            let notificationRequest = UNNotificationRequest(identifier: "bce_test_notification", content: notificationContent, trigger: trigger)
            
            UNUserNotificationCenter.current().add(notificationRequest) { (error) in
                if let error = error {
                    print("Unable to Add Notification Request (\(error), \(error.localizedDescription))")
                }
            }
            let df = DateFormatter()
            df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
            let notifid = type //(String(describing: notificationRequest.identifier) + "_type_\(ntype)")
           
            var fdate = " "
            if let fd = trigger.nextTriggerDate() {
                fdate = df.string(from: fd)
            }
      
            notificationFeedback.append(["studyId" : studyID ,"fired_datetime" : fdate, "response_datetime" : "not_yet", "fired_notification_id" : notificationRequest.identifier, "notification_id" : "type_\(notification_counter)", "response" : "not_yet"])
        }
    }
    
    func randomReminderTime() -> Int {
        var rtime = 60
        let temp = Double(arc4random()) / Double(UInt32.max)
        
        if temp <= 0.2  {
        //Keep before_time at 60
        } else if temp > 0.2 && temp <= 0.4  {
        rtime = 90
        } else if temp > 0.4 && temp <= 0.6  {
        rtime = 120
        } else if temp > 0.6 && temp <= 0.8 {
        rtime = 150
        } else if temp > 0.8 && temp <= 1 {
        rtime = 180
        }
        return rtime
    }
}
