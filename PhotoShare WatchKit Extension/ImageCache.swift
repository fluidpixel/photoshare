//
//  ImageCache.swift
//  PhotoShare
//
//  Created by Paul on 29/09/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation
import WatchConnectivity
import WatchKit

let USER_DEFAULTS = NSUserDefaults(suiteName: "group.com.fpstudios.WatchKitPhotoShare")

private let kCacheIndexKey = "kCacheIndexKey"
private let kCacheIndexURLKey = "kCacheIndexURLKey"
private let kCacheIndexModifiedDateKey = "kCacheIndexModifiedDateKey"
private let kCacheIndexDegradedKey = "kCacheIndexDegradedKey"


extension NSDate : Comparable {}
public func < (left:NSDate, right:NSDate) -> Bool { return left.compare(right) == NSComparisonResult.OrderedAscending }

private func cacheFolder() -> NSURL {
    let cache = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
    return NSURL(fileURLWithPath: cache, isDirectory: true)
}

private func createCacheFilename(pathExtension:String) throws -> NSURL {
    let rv = cacheFolder().URLByAppendingPathComponent(NSUUID().UUIDString).URLByAppendingPathExtension(pathExtension)
    
    if NSFileManager.defaultManager().fileExistsAtPath(rv.path!) {
        try NSFileManager.defaultManager().removeItemAtURL(rv)
    }

    return rv
}


enum IncorrectMetaData : ErrorType {
    case LocalIdentifierMissing
    case ModifiedDateMissing
}


struct ImageCacheData {
    let url:NSURL
    let modifiedDate:NSDate
    let degraded:Bool
    
    
    init(url u: NSURL, modifiedDate md: NSDate, degraded dg: Bool) {
        self.url = u
        self.modifiedDate = md
        self.degraded = dg
    }
    
    init?(dictionary:[String:AnyObject]) {
        
        guard let file = dictionary[kCacheIndexURLKey] as? String else { return nil }
        
        // Myterious double optional
        guard let md = dictionary[kCacheIndexModifiedDateKey] as? NSDate else { return nil }
        
        guard let dg = dictionary[kCacheIndexDegradedKey]?.boolValue else { return nil }
        
        self.url = cacheFolder().URLByAppendingPathComponent(file)
        self.modifiedDate = md
        self.degraded = dg
    }
    
    var dictionaryValue:[String:AnyObject] {
        return [kCacheIndexURLKey:url.lastPathComponent!, kCacheIndexModifiedDateKey:modifiedDate, kCacheIndexDegradedKey:degraded]
    }
}



class ImageCache {
    
    init(clear:Bool = false) {
        
        self.imageCache = [:]
        
        if clear, let files = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(cacheFolder(), includingPropertiesForKeys: nil, options: []) {
            print("Cache cleanup")
            for file in files {
                print("removing ItemAtURL \(file)")
                
                try! NSFileManager.defaultManager().removeItemAtURL(file)
            }
        }
        else {
            // restore cache from user defaults
            if let rawIndex = USER_DEFAULTS?.dictionaryForKey(kCacheIndexKey) as? [String:[String:AnyObject]] {
                
                for (localID, dictionary) in rawIndex {
                    if let cacheData = ImageCacheData(dictionary: dictionary),
                        let path = cacheData.url.path where NSFileManager.defaultManager().fileExistsAtPath(path) {
                            self.imageCache[localID] = cacheData
                    }
                }
            }
        }

        // TODO: Check this cleanup become unnecessary
        if let files = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(cacheFolder(), includingPropertiesForKeys: nil, options: []) {
            let unusedCacheFiles = Set<NSURL>(files).subtract(indexedURLs)
            if unusedCacheFiles.count == 0 {
                print("No unused files in cache")
            }
            else {
                print("Removing \(unusedCacheFiles.count) usused files from cache")
                for file in unusedCacheFiles {
                    try! NSFileManager.defaultManager().removeItemAtURL(file)
                }
            }
        }
    }
    
    // MARK: Cache elements
    private var imageCache:[String:ImageCacheData] {
        didSet {
            let cache = self.imageCache
            var rawIndex:[String:[String:AnyObject]] = [:]
            for (localID, data) in cache {
                rawIndex[localID] = data.dictionaryValue
            }
            USER_DEFAULTS?.setObject(rawIndex, forKey: kCacheIndexKey)
        }
    }
    private var cachedIDsAll:Set<String> { return Set<String>(self.imageCache.keys) }
    private var cachedIDsHQ:Set<String> { return Set<String>(self.imageCache.filter { !$0.1.degraded }.map { $0.0 }) }
    private var indexedURLs:Set<NSURL> { return Set<NSURL>(self.imageCache.map { $0.1.url }) }
        
    subscript(localID:String) -> NSData? {
        if let url = self.imageCache[localID]?.url {
            return NSData(contentsOfURL: url)
        }
        
        // could not retrieve image data so remove index from cache
        self.removeItem(localID)
        return nil
    }
    
    func removeItem(localID:String) -> Bool {
        if let removedItem = self.imageCache.removeValueForKey(localID) {
            try! NSFileManager.defaultManager().removeItemAtURL(removedItem.url)
            return true
        }
        return false
    }
    
    func insertItem(localID:String, item:ImageCacheData, force:Bool = false) -> Bool {

        if !force, let existingItem = self.imageCache[localID] {
            
            if existingItem.modifiedDate > item.modifiedDate {
                return false
            }
            else if existingItem.modifiedDate == item.modifiedDate && !existingItem.degraded && item.degraded {
                return false
            }
            
        }
        
        if let replacedItem = self.imageCache.updateValue(item, forKey: localID) {
            if replacedItem.url != item.url { // very unlikely
                try! NSFileManager.defaultManager().removeItemAtURL(replacedItem.url)
            }
        }
        
        return true
        
    }
    
    func insertItem(receivedFile file: WCSessionFile, forceRefresh:Bool) throws -> Bool {
        
        guard let newLocalID = file.metadata?[kLocalIdentifier] as? String else { throw IncorrectMetaData.LocalIdentifierMissing }
        guard let newModifiedDate = file.metadata?[kAssedModificationDate] as? NSDate else { throw IncorrectMetaData.ModifiedDateMissing }
        
        let newDegraded:Bool = file.metadata?["PHImageResultIsDegradedKey"]?.boolValue ?? false
        
        let newURL = try createCacheFilename(file.fileURL.pathExtension!)
        
        try NSFileManager.defaultManager().moveItemAtURL(file.fileURL, toURL: newURL)
        
        let newItem = ImageCacheData(url: newURL, modifiedDate: newModifiedDate, degraded: newDegraded)
        
        return self.insertItem(newLocalID, item: newItem, force: forceRefresh)
        
    }
    
    func urlIsRequired(url:NSURL) -> Bool {
        for item in self.imageCache {
            if item.1.url == url {
                return true
            }
        }
        return false
    }
    
    // cleanup functions - update cache contents removing unused items and returning a set of required images
    func cleanupAndRefresh(localIDs:[String]) -> [String] {
        return [String](cleanupAndRefresh(localIDs: Set<String>(localIDs)))
    }
    
    func cleanupAndRefresh(localIDs required:Set<String>) -> Set<String> {
        for id in self.cachedIDsHQ.subtract(required) {
            self.removeItem(id)
        }
        return required.subtract(self.cachedIDsHQ)
    }
    
    func imagesRequiringRefresh(list:[String:NSDate]) -> [String] {
        var rv:[String] = []
        for item in list {
            if let eDate = self.imageCache[item.0]?.modifiedDate {
                if eDate < item.1 {
                    rv.append(item.0)
                }
            }
        }
        
        return rv
    }
}

