//
//  Memo+CoreDataProperties.swift
//  
//
//  Created by Soso on 2020/05/25.
//
//

import Foundation
import CoreData
import RxDataSources

extension Memo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Memo> {
        return NSFetchRequest<Memo>(entityName: "Memo")
    }

    @NSManaged public var title: String
    @NSManaged public var text: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var modifiedAt: Date
    @NSManaged public var id: String

}

extension Memo: IdentifiableType {
    public typealias Identity = String
    
    public var identity: String {
        return id
    }
}
