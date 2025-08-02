//
//  NewsItem+CoreDataProperties.swift
//  NewsReader
//
//  Created by Conan on 02/08/2025.
//
//

import Foundation
import CoreData


extension NewsItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NewsItem> {
        return NSFetchRequest<NewsItem>(entityName: "NewsItem")
    }

    @NSManaged public var title: String
    @NSManaged public var content: String?
    @NSManaged public var postId: Int32
    @NSManaged public var publishDate: Date?

}