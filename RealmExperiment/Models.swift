//
//  Models.swift
//  RealmExperiment
//
//  Created by Cali Castle on 5/15/18.
//  Copyright © 2018 Cali Castle. All rights reserved.
//

import Foundation
import RealmSwift

class Todo: Object {
    @objc dynamic var name = ""
    @objc dynamic var finished = false
}
