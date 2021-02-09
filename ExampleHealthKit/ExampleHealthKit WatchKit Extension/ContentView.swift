//
//  ContentView.swift
//  ExampleHealthKit WatchKit Extension
//

import SwiftUI
import HealthKit

extension Date {
    static func mondayAt12AM() -> Date {
        return Calendar(identifier: .iso8601).date(from: Calendar(identifier: .iso8601)
                                                    .dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
    }
}

struct ContentView: View {
    
    public var healthStore: HKHealthStore?
    let startDate = Calendar.current.date(byAdding: .minute, value: -15, to: Date())!
    @State private var steps: [StepList] = [StepList]()

    
    // MARK: - Check if Data is available and initialize HealthStore
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    var body: some View {
        
        List(steps, id: \.id) { entry in
            VStack{
                Text("\(entry.value)")
                Text(entry.date, style: .time)
                    .opacity(0.5)
            }
        }
            
            .onAppear(){
                // MARK: - Execute Request Authorization
                requestAuthorization{ success in
                    // execute calculate steps
                    calculateSteps{ statisticsCollection in
                        if let statisticsCollection = statisticsCollection {
                            // UpdateUI
                            updateUiFromStatistics(statisticsCollection)
                        }
                    }
                }
            }
    }
    
    // MARK: - Function Update UI
    func updateUiFromStatistics(_ statisticsCollection: HKStatisticsCollection){
        
        statisticsCollection.enumerateStatistics(from: startDate, to: Date()){statistics, stop in
            let value = statistics.sumQuantity()?.doubleValue(for: .count())
            let stepEntry = StepList(value: Int(value ?? 0), date: statistics.startDate)
            
            steps.append(stepEntry)
        }
    }
    
    // MARK: - Func Calculate Steps
    func calculateSteps(completion: @escaping (HKStatisticsCollection?) -> Void){
        let type = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
        let anchorDate = Date.mondayAt12AM()
        let interval = DateComponents(minute: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: predicate,
                                                options: .cumulativeSum, anchorDate: anchorDate, intervalComponents: interval)
        
        query.initialResultsHandler = { query, statisticsCollection, error in
            completion(statisticsCollection)
        }
        
        if let healthStore = self.healthStore{
            healthStore.execute(query)
        }
    }
    
    // MARK: - Func Request Authorization
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!
        ]
        
        healthStore?.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            completion(success)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
