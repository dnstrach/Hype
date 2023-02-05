//
//  UserController.swift
//  HypeDemo
//
//  Created by Dominique Strachan on 2/4/23.
//

import UIKit
import CloudKit

class UserController {
    
    //shared instance
    static let shared = UserController()
    
    //source of truth
    var currentUser: User?
    
    //database constant
    let publicDB = CKContainer.default().publicCloudDatabase
    
    //MARK: - CRUD
    func createUser(with username: String, bio: String, profilePhoto: UIImage?, completion: @escaping (Bool) -> Void) {
        //fetching the CKUserIdentity recordID, creating a reference to use with our User object
        fetchAppleUserReference { (reference) in
            //ensure that we can unwrap reference
            guard let reference = reference else { completion(false) ; return }
            //init a newUser with the reference
            let newUser = User(username: username, bio: bio, profilePhoto: profilePhoto, appleUserReference: reference)
            //create the CKRecord to be saved from the newUser
            let record = CKRecord(user: newUser)
            
            //call the .save method to save the newly created CKRecord
            self.publicDB.save(record) { (record, error) in
                //handle the error
                if let error = error {
                    print("Error in \(#function) : \(error.localizedDescription) \n--\n \(error)")
                    completion(false)
                    return
                }
                
                //unwrap the record that was saved, ensure that we can init a user from that record
                guard let record = record,
                      let savedUser = User(ckRecord: record)
                else { completion(false) ; return }
                //set the currentUser and complete true
                self.currentUser = savedUser
                print("Created user: \(record.recordID.recordName) successfully")
                completion(true)
            }
        }
    }
    
    func fetchUser(completion: @escaping (Bool) -> Void) {
        //step 4 - fetch and unwrap the appleUserRef to use in our predicate
        fetchAppleUserReference { (reference) in
            guard let reference = reference else { completion(false) ; return }
            //step 3 - define the predicate
            //takes an array of arguments and passes them into the format, the first item in the array is being passed to %K(Key), and the second item in the array is being passed into the %@(value)
            let predicate = NSPredicate(format: "%K == %@", argumentArray: [UserStrings.appleUserReferenceKey, reference])
            //step 2 - init the query
            let query = CKQuery(recordType: UserStrings.recordTypeKey, predicate: predicate)
            //step 1 - perform the query
            self.publicDB.perform(query, inZoneWith: nil) { (records, error) in
                if let error = error {
                    print("Error in \(#function) : \(error.localizedDescription) \n--\n \(error)")
                    completion(false)
                    return
                }
                
                guard let record = records?.first,
                      let foundUser = User(ckRecord: record)
                else { completion(false) ; return }
                
                self.currentUser = foundUser
                print("Fetched User: \(record.recordID.recordName) successfully")
                completion(true)
            }
            
        }
    }
    
    private func fetchAppleUserReference(completion: @escaping (CKRecord.Reference?) -> Void) {
        CKContainer.default().fetchUserRecordID { recordID, error in
            if let error = error {
                print("Error in \(#function) : \(error.localizedDescription) \n--\n \(error)")
                return
            }
            
            guard let recordID = recordID else { completion(nil) ; return}
            let reference = CKRecord.Reference(recordID: recordID, action: .deleteSelf)
            completion(reference)
        }
    }
    
    func update(_ user: User) {
        
    }
    
    func delete(_ user: User) {
        
    }
}
