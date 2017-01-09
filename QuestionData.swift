//
//  questionData.swift
//  SpriteKitSimpleGame
//
//  Created by Kylee Davis on 1/7/17.
//  Copyright © 2017 Kylee Davis. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDatabase

struct QuestionData {
    let key: String
    var question: String
    var answers: [String: Bool]
    let ref: FIRDatabaseReference?
    
    init(question: String, answers: [String: Bool], key: String = "") {
        self.key = key
        self.question = question
        self.answers = answers
        self.ref = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        let snapshotValue = snapshot.value as! [String: AnyObject]
        question = snapshotValue["question"] as! String
        answers = snapshotValue["answers"] as! [String: Bool]
        ref = snapshot.ref
    }
}
