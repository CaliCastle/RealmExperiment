//
//  ToDo.swift
//  TooDoo
//
//  Created by Cali Castle  on 5/22/18.
//  Copyright © 2018 Cali Castle . All rights reserved.
//

import EventKit
import Foundation
import RealmSwift

public class ToDo: Object {
    
    @objc dynamic private(set) var id: String?
    
    /// Dates
    @objc dynamic private(set) var createdAt: Date = Date()
    @objc dynamic private(set) var updatedAt: Date = Date()
    @objc dynamic var dueAt: Date?
    @objc dynamic var remindAt: Date?
    @objc dynamic var completedAt: Date?
    @objc dynamic var movedToTrashAt: Date?
    
    @objc dynamic var goal: String = ""
    @objc dynamic var notes: String?
    
    @objc dynamic fileprivate var repeatInfo: Data?
    
    @objc dynamic private(set) var systemEventIdentifier: String?
    @objc dynamic private(set) var systemReminderIdentifier: String?
    
    override public static func primaryKey() -> String? {
        return "id"
    }
    
    @objc dynamic var list: ToDoList?

    public static func make() -> ToDo {
        let todo = self.init()
        todo.id = UUID().uuidString
        
        return todo
    }
}

extension ToDo {
    
    /// Repeat types.
    public enum RepeatType: String, Codable {
        case None
        case Daily
        case Weekly
        case Weekday
        case Monthly
        case Annually
        case Regularly
        case AfterCompletion
    }
    
    /// Repeat regularly unit.
    public enum RepeatUnit: String, Codable {
        case Minute
        case Hour
        case Day
        case Weekday
        case Week
        case Month
        case Year
    }
    
    /// Repeat structure.
    struct Repeat: Codable {
        var type: RepeatType = .None
        var frequency: Int = 1
        var unit: RepeatUnit = .Day
        var endDate: Date?
        
        func getNextDate(_ date: Date) -> Date? {
            let info = self
            
            var component: Calendar.Component = .day
            var amount: Int = info.frequency
            
            switch info.type {
            case .None:
                return nil
            case .Daily:
                component = .day
                amount = 1
            case .Weekday:
                component = .weekday
                amount = 1
            case .Weekly:
                component = .day
                amount = 7
            case .Monthly:
                component = .month
                amount = 1
            case .Annually:
                component = .year
                amount = 1
            case .Regularly, .AfterCompletion:
                switch info.unit {
                case .Minute:
                    component = .minute
                case .Hour:
                    component = .hour
                case .Month:
                    component = .month
                case .Weekday:
                    component = .weekday
                case .Week:
                    amount = amount * 7
                case .Year:
                    component = .year
                default:
                    break
                }
            }
            
            // Get initial next date
            var nextDate: Date = info.type == .AfterCompletion ? Date() : date
            
            if component == .weekday {
                // Calculate next weekday
                
            } else {
                // Calculate next by component
                nextDate = Calendar.current.date(byAdding: component, value: amount, to: nextDate)!
            }
            
            // Add renewal calculation
            return nextDate
        }
    }
    
    /// Repeat types.
    static let repeatTypes: [RepeatType] = [
        .None, .Daily, .Weekday, .Weekly, .Monthly, .Annually, .Regularly, .AfterCompletion
    ]
    
    /// Repeat units.
    static let repeatUnits: [RepeatUnit] = [
        .Minute, .Hour, .Day, .Weekday, .Week, .Month, .Year
    ]
    
    /// Retrieve repeat info.
    func getRepeatInfo() -> ToDo.Repeat? {
        if let data = repeatInfo {
            return try? JSONDecoder().decode(ToDo.Repeat.self, from: data)
        }
        
        return nil
    }
    
    /// Set repeat info to data.
    func setRepeatInfo(info: ToDo.Repeat?) {
        if let info = info {
            if let data = try? JSONEncoder().encode(info) {
                repeatInfo = data
            }
        }
    }
}
