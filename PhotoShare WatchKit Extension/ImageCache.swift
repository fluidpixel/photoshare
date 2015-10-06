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

enum CacheIndexKeys : String {
    case CacheIndex
    case Filename
    case ModifiedDate
    case Degraded
}

private let kCacheIndexKey = "kCacheIndexKey"
private let kCacheIndexFilenameKey = "kCacheIndexFilenameKey"
private let kCacheIndexModifiedDateKey = "kCacheIndexModifiedDateKey"
private let kCacheIndexDegradedKey = "kCacheIndexDegradedKey"


extension NSDate : Comparable {}
public func < (left:NSDate, right:NSDate) -> Bool { return left.compare(right) == NSComparisonResult.OrderedAscending }

private func cacheFolder() -> NSURL {
    let cache = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first!
    return NSURL(fileURLWithPath: cache, isDirectory: true)
}

enum IncorrectMetaData : ErrorType {
    case LocalIdentifierMissing
    case ModifiedDateMissing
}


struct ImageCacheData {
    let modifiedDate:NSDate
    let degraded:Bool
    let filename:String
    
    var url:NSURL { return cacheFolder().URLByAppendingPathComponent(filename) }
    
    init(filename fn:String, modifiedDate md: NSDate, degraded dg: Bool) {
        self.filename = fn
        self.modifiedDate = md
        self.degraded = dg
    }
    
    init?(dictionary:[String:AnyObject]) {
        
        guard let file = dictionary[kCacheIndexFilenameKey] as? String else { return nil }
        
        // Myterious double optional
        guard let md = dictionary[kCacheIndexModifiedDateKey] as? NSDate else { return nil }
        
        guard let dg = dictionary[kCacheIndexDegradedKey]?.boolValue else { return nil }
        
        self.filename = file
        self.modifiedDate = md
        self.degraded = dg
    }
    
    var dictionaryValue:[String:AnyObject] {
        return [kCacheIndexFilenameKey:self.filename, kCacheIndexModifiedDateKey:modifiedDate, kCacheIndexDegradedKey:degraded]
    }
}



class ImageCache {
    
    init(clear:Bool = false) {
        
        self.imageCache = [:]
        
        if clear,
            let files = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(cacheFolder(), includingPropertiesForKeys: nil, options: [])
            where files.count > 0 {
            print("Cache cleanup")
            
            USER_DEFAULTS?.removeObjectForKey(kCacheIndexKey)
            
            for file in files {
                print("removing ItemAtURL \(file)")
                
                try! NSFileManager.defaultManager().removeItemAtURL(file)
            }
            abort()
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
            do {
                try NSFileManager.defaultManager().removeItemAtURL(removedItem.url)
                return true
            }
            catch {
                print("Could not remove file : \(removedItem.url)")
                return false
            }
        }
        return false
    }
    
    
    func insertItem(receivedFile file: WCSessionFile) -> Bool {
        
        guard let newLocalID = file.metadata?[kLocalIdentifier] as? String else {
            print(IncorrectMetaData.LocalIdentifierMissing)
            return false
        }
        
        guard let newModifiedDate = file.metadata?[kAssetModificationDate] as? NSDate else {
            print(IncorrectMetaData.ModifiedDateMissing)
            return false
        }
        
        let newDegraded:Bool = file.metadata?["PHImageResultIsDegradedKey"]?.boolValue ?? true
        
        let newItem = ImageCacheData(filename: file.fileURL.lastPathComponent!, modifiedDate: newModifiedDate, degraded: newDegraded)
        
        if let existingItem = self.imageCache[newLocalID] {
            // Already in cache - check it is not new or not degraded
            
            if existingItem.modifiedDate > newModifiedDate {
                return false
            }
            else if existingItem.modifiedDate == newModifiedDate && !existingItem.degraded && newDegraded {
                return false
            }
            
            do {
                try NSFileManager.defaultManager().removeItemAtURL(existingItem.url)
            }
            catch let error as NSError {
                print("Unexpectedly, \(existingItem.url) does not exist or can't be deleted. \(error)")
            }
            
        }
        
        do {
            try NSFileManager.defaultManager().moveItemAtURL(file.fileURL, toURL: newItem.url)
            self.imageCache.updateValue(newItem, forKey: newLocalID)
            return true
        }
        catch let error as NSError {
            print("Unexpectedly, \(newItem.url) can't be created. \(error)")
            return false
        }
        
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
            if let cachedImageData = self.imageCache[item.0] {
                if cachedImageData.degraded || cachedImageData.modifiedDate < item.1 {
                    rv.append(item.0)
                }
            }
            else {
                rv.append(item.0)
            }
        }
        
        return rv
    }
}
