//  Copyright © 2018 IBM.

import Foundation
import HealthKit

let healthStore = HKHealthStore()

class HealthKitData {
 
    class func getProfile() throws -> ([[String: String]]) {
        
        var biologicalSex = HKBiologicalSexObject()
        var dateOfBirth = DateComponents()
        var birthdate = ""
        let today = Date()
        let calendar = Calendar.current
        var age = "undefined"
        do {
            // Obtain HK profile components
            biologicalSex = try healthStore.biologicalSex()
        } catch {
        }
        
        do {
            
            // Used only to compute age, date of birth not stored anymore
            dateOfBirth = try healthStore.dateOfBirthComponents()
            let dob = Calendar.current.date(from: dateOfBirth)!
            let dateF = DateFormatter()
            dateF.dateFormat = "yyyy-MM-dd"
            birthdate = dateF.string(from: dob)
            let todayDateComponents = calendar.dateComponents([.year], from: today)
            let thisYear = todayDateComponents.year!
            var t_age = thisYear - dateOfBirth.year!
            
            //Bucketizing age to satisfy study requirements
            if t_age >= 18 && t_age < 22 {
                age = "18-22"
            } else if t_age >= 22 && t_age < 25 {
                age = "22-25"
            } else if t_age >= 25 && t_age < 30 {
                age = "25-30"
            } else if t_age >= 30 && t_age < 35 {
                age = "30-35"
            } else if t_age >= 35 && t_age < 40 {
                age = "35-40"
            } else if t_age >= 40 {
                age = "40+"
            }
            
            
        } catch {
            //dateOfbirth = "None"
            birthdate = "None"
            
        } 

        // Return text values for each parameter
        let textBiologicalSex = gType(g: biologicalSex.biologicalSex)
 
        return [["studyId" : "\(studyID)", "age" : "\(age)", "gender" : textBiologicalSex, "blood_type" : "NA", "fst" : "NA", "DOB" : "NA", "baseline" : "0"]]
   
    }
    
    class func json(dat: [String]) -> String? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dat, options: JSONSerialization.WritingOptions.prettyPrinted)
        
            return String(data: data, encoding: String.Encoding.utf8)
        } catch {return(error.localizedDescription)}
    }
    
    //Loop over types above
    class func getSamples(minsAgo: Int, endDate: Date, completion: @escaping ([[String: String]])-> Void) {
        var interval = DateComponents()
        interval.day = 1
        var tracker = [[String : String]]()
        
        let startDate = Calendar.current.date(byAdding: .minute, value: -1*minsAgo, to: Date()) as! Date
        let calendar = Calendar.current
        let unitFlags = Set<Calendar.Component>([.day, .month, .year, .hour])
        let anchorComponents = calendar.dateComponents(unitFlags, from: startDate,  to: endDate as Date)
        
        guard let anchorDate = calendar.date(from: anchorComponents) else {
            fatalError("*** unable to create a valid date from the given components ***")
        }
        guard let quantTypeSteps = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            fatalError("*** Unable to create a step count type ***")
        }
        guard let quantTypeDistanceWalkingRunning = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning) else {
            fatalError("*** Unable to create a distanceWalkingRunning type ***")
        }
        guard let quantDistanceCycling = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling) else {
            fatalError("*** Unable to create a distanceCycling type ***")
        }
        guard let quantTypeHR = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            fatalError("*** Unable to create a heartRate type ***")
        }
        guard let quantTypeWalkingHR = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.walkingHeartRateAverage) else {
            fatalError("*** Unable to create a walkingHeartRate type ***")
        }
        guard let quantTypeRestHR = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate) else {
            fatalError("*** Unable to create a restingHeartRate type ***")
        }
        guard let quantFlightsClimbed = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed) else {
            fatalError("*** Unable to create a flightsClimbed type ***")
        }
        guard let quantTypeActiveEnergy = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned) else {
            fatalError("*** Unable to create an activeEnergy type ***")
        }
        guard let quantTypeDietaryEnergy = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed) else {
            fatalError("*** Unable to create a resting dietaryEnergy type ***")
        }
        guard let quantTypeMass = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass) else {
            fatalError("*** Unable to create a bodyMass type ***")
        }
        
        let types = [quantTypeSteps, quantTypeDistanceWalkingRunning, quantDistanceCycling, quantFlightsClimbed, quantTypeActiveEnergy, quantTypeDietaryEnergy, quantTypeHR, quantTypeWalkingHR, quantTypeRestHR, quantTypeMass ]
        for q in types {
            guard let anchorDate = calendar.date(from: anchorComponents) else {
                fatalError("*** unable to create a valid date from the given components ***")
            }
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: [])
            
            var query = HKSampleQuery(sampleType: q, predicate: predicate, limit: 5000, sortDescriptors: nil, resultsHandler: {
                query, results, error in
                if let results = results as? [HKQuantitySample]
                {
                    if results.count > 0 {
                        for i in results {
                            let df = DateFormatter()
                            df.dateFormat = "MM/dd/yyyy hh:mm:ss a"
                            var v = String(describing: i.quantity).components(separatedBy: " ")
                            var dv = String(describing: i.device)
                            var mf = ""
                            var qt = ""
                            
                            if let test = (i.metadata?[HKMetadataKeyWasUserEntered] as? Bool)?.description {
                                mf = test
                            } else {
                                mf = " "
                            }
                            
                            if let d = i.quantityType.description as? String {
                                qt = d
                            } else {
                                qt = " "
                            }
                            
                            if let d = i.device?.description as? String {
                                dv = d
                            } else {
                                dv = " "
                            }

                            let isd = df.string(from:i.startDate)
                            let ied = df.string(from:i.endDate)
                         
                            (tracker).append(["studyId" : "\(studyID)", "type": "\(qt)", "value" : "\(v[0])", "unit" : "\(v[1])", "start_date" : df.string(from:i.startDate), "end_date" : df.string(from:i.endDate), "device" : dv , "manual_flag" : "\(mf)" ])
                        }
                        completion(tracker)
                    }
                }
            })
            HKHealthStore().execute(query)
        }
    }

    class func getSteps(daysAgo: Int, endDate: Date, completion: @escaping (_ weekCount: [String: Double]) -> Void) {
        //let calendar = Calendar.current
        var interval = DateComponents()
        interval.day = 1
        var weekCount = [String: Double]()
        let startDate = Calendar.current.date(byAdding: .day, value: -1*daysAgo, to: endDate) as! Date
        let calendar = Calendar.current
        let unitFlags = Set<Calendar.Component>([.day, .month, .year, .hour])
        let anchorComponents = calendar.dateComponents(unitFlags, from: startDate,  to: endDate as Date)

        guard let anchorDate = calendar.date(from: anchorComponents) else {
            fatalError("*** unable to create a valid date from the given components ***")
        }
        
        guard let quantTypeSteps = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            fatalError("*** Unable to create a step count type ***")
        }
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yyyy"
        
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: quantTypeSteps, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: interval)
        var value = 0.0
        var value_sum = 0.0
        // Set the results handler
        query.initialResultsHandler = {
            query, results, error in
            
            guard let statsCollection = results else {
                // Perform proper error handling here
                print("*** An error occurred while calculating the statistics: \(error?.localizedDescription) ***")
                return
            }
            
            // Plot the weekly step counts over the past 3 months
            statsCollection.enumerateStatistics(from: startDate, to: endDate) {  statistics, stop in
                
                if let quant = statistics.sumQuantity() {
                   let date = statistics.startDate
                    value = quant.doubleValue(for: HKUnit.count())
                    value_sum += value
                    weekCount[df.string(from: date)] = (value)
                }
            }
            DispatchQueue.main.async {
                completion(weekCount)
            }
            
        }
        healthStore.execute(query)
    }
    
    class func getTodaysSteps(completion: @escaping (_ stepsRetreived: String) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 0, to: now)!)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        var interval = DateComponents()
        interval.day = 1
        var value = 0.0
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            var resultCount = 0.0
            guard let result = result else {
                completion(String("\(error?.localizedDescription ?? "N/A")"))
                return
            }
            
            if let sum = result.sumQuantity() {
                resultCount = sum.doubleValue(for: HKUnit.count())
                let sDate = result.startDate
                let eDate = result.endDate
                 value = sum.doubleValue(for: HKUnit.count())
            } else {
                print("result is: \(result)")
                completion(String("\(error?.localizedDescription ?? "N/A")"))
                return
            }
            DispatchQueue.main.async {
                completion(String(value))
            }
        }
        healthStore.execute(query)
    }
    
    //Functions to map HK value codes to descriptive strings
    class func gType(g: HKBiologicalSex) -> String {
        switch g {
            case .notSet: return "Unknown"
            case .female: return "Female"
            case .male: return "Male"
            case .other: return "Other"
        }
    }
}
