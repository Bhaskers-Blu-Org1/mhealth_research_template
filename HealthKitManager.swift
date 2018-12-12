// Copyright © 2018 IBM.

import Foundation
import UIKit
import HealthKit

class HealthKitManager {
    
    let healthStore = HKHealthStore()

    func authorizeHealthkit() -> Bool {
        var isEnabled = true // Assume true by default
        
        if HKHealthStore.isHealthDataAvailable()  { // Confirmation that HealthKit is available on the phone
            
            //MARK: Metrics
            let stepCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
            let distance = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
            let restingHR = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate)
            let HR = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)
            let walkingHR = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.walkingHeartRateAverage)
            let mass = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)
            let cyclingDistance = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceCycling)
            let flights = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.flightsClimbed)
            let activeEnergy = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)
            let dietaryEnergy = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryEnergyConsumed)
            
            //MARK: Participant profile & demographics
            let dateOfBirth = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)

            let biologicalSex = HKObjectType.characteristicType(forIdentifier: .biologicalSex)
            let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex)
            let height = HKObjectType.quantityType(forIdentifier: .height)
            let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass)
            
            let readData: Set<HKObjectType> = [dateOfBirth!, biologicalSex!, bodyMassIndex!, height!, bodyMass!, stepCount!, distance!, mass!, restingHR!, walkingHR!, HR!, flights!, cyclingDistance!, activeEnergy!, dietaryEnergy!]
            
            // Request authorization to access HealthKit readData
            healthStore.requestAuthorization(toShare: nil, read: (readData as Set<HKObjectType>)) {
                (success, error) -> Void in
                
                isEnabled = success

            }} else {
                isEnabled = false
            }
        return isEnabled
    }
}
