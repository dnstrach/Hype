//
//  HypeController.swift
//  HypeDemo
//
//  Created by Dominique Strachan on 1/30/23.
//

import UIKit
import CloudKit

class HypeController {
    
    //shared instance
    static let shared = HypeController()
    
    //source of truth
    var hypes: [Hype] = []
    
    //Constant to access our publicCloudDatabase
    let publicDB = CKContainer.default().publicCloudDatabase
    
    //MARK: - CRUD
    //Create
    func saveHype(with text: String, photo: UIImage?, completion: @escaping (Bool) -> Void) {
        guard let currentUser = UserController.shared.currentUser else {
            completion(false) ; return }
        let reference = CKRecord.Reference(recordID: currentUser.recordID, action: .none)
        //initialize hype object
        let newHype = Hype(body: text, hypePhoto: photo, userReference: reference)
        //package new hype into ckRecord
        let hypeRecord = CKRecord(hype: newHype)
        
        //saving hype record to cloud
        publicDB.save(hypeRecord) { (record, error) in
            //handling error if there is one
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n--\n \(error)")
                completion(false)
                return
            }
            
            //unwrapping the record that was saved
            guard let record = record,
                  //ensuring that we can init a hype from that record
                  let savedHype = Hype(ckRecord: record)
            else { completion(false) ; return }
            
            //Add it to our source of truth array
            print("Saved hype successfully")
            self.hypes.insert(savedHype, at: 0)
            completion(true)
            
        }
    }
    
    //fetch
    func fetchHypes(completion: @escaping (Bool) -> Void) {
        
        //step 3 - initialize the requisite predicate for the query
        let predicate = NSPredicate(value: true)
        //step 2 - initialize the requisite query for the .perform method
        let query = CKQuery(recordType: HypeStrings.recordTypeKey, predicate: predicate)
        
//        publicDB.fetch(withQuery: <#T##CKQuery#>, completionHandler: <#T##(Result<(matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?), Error>) -> Void#>)
        
        //step 1 = perform query on database
        publicDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n--\n \(error)")
                completion(false)
                return
            }
            
            //unwrap found records
            guard let records = records else { completion(false) ; return }
            print("Fetched all hypes")
            
            //compact map through the found records to return an array of non-nil Hype objects
            let fetchedHypes = records.compactMap { Hype(ckRecord: $0) }
            //set source of truth
            self.hypes = fetchedHypes
            
            completion(true)
        }
    }
    
    func update(_ hype: Hype, completion: @escaping (Bool) -> Void) {
        
        guard hype.userReference?.recordID == UserController.shared.currentUser?.recordID else { completion(false) ; return }
        //Define the record/s to be updated
        let recordToUpdate = CKRecord(hype: hype)
        //step 2 - create the requisite operation
        let operation = CKModifyRecordsOperation(recordsToSave: [recordToUpdate])
        //step 3 - set properties for the operation
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInteractive
        //operation.modifyRecordsResultBlock =
        operation.modifyRecordsCompletionBlock = { (records, _, error) in
            //handle error
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n--\n \(error)")
                completion(false)
                return
            }
            //ensure records were returned and updated
            guard let record = records?.first else { completion(false) ; return }
            print("Updated \(record.recordID.recordName) successfully in CloudKit")
            completion(true)
        }
        
        //step 1 - add operation to the database
        publicDB.add(operation)
    }
    
    func delete(_ hype: Hype, completion: @escaping (Bool) -> Void) {
        guard hype.userReference?.recordID == UserController.shared.currentUser?.recordID else { completion(false) ; return }
        //step 2 - declare the operation
        let operation = CKModifyRecordsOperation(recordIDsToDelete: [hype.recordID])
        //step 3 - set properties on the operation
        operation.savePolicy = .changedKeys
        operation.qualityOfService = .userInteractive
        operation.modifyRecordsCompletionBlock = { (records, recordIDs, error) in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n--\n \(error)")
                completion(false)
                return
            }
            
            guard let recordIDs = recordIDs else { completion(false) ; return }
                print("\(recordIDs) Records were removed successfully")
                completion(true)
        }
        
        //step 1 - add operation to the database
        publicDB.add(operation)
    }
    
    func subscribeForRemoteNotifications(completion: @escaping (Error?) -> Void) {
       
        //step 3 - declare the requisite predicate
        let predicate = NSPredicate(value: true)
        
        //step 2 - declare the subscription
        let subscription = CKQuerySubscription(recordType: HypeStrings.recordTypeKey, predicate: predicate, options: .firesOnRecordCreation)
        
        //step 4 - setting the subscription properties
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.title = "CHOO CHOO"
        notificationInfo.alertBody = "Can't stop the hype train"
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        subscription.notificationInfo = notificationInfo
        
        //step 1 - call the save (subscription_ function on the database
        publicDB.save(subscription) { (_, error) in
            if let error = error {
//                print("Error in \(#function) : \(error.localizedDescription) \n--\n \(error)")
                completion(error)
            }
            completion(nil)
        }
    }
}
