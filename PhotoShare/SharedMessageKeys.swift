//
//  SharedMessageKeys.swift
//  PhotoShare
//
//  Created by Paul on 23/09/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation

// Keys used for messages between Phone and Watch

let kApplicationDidFinishLaunching = "kApplicationDidFinishLaunching"

let kRequestLocalIdentifierList = "kRequestLocalIdentifierList"
let kLocalIdentifierList = "kLocalIdentifierList"

let kAssetsLastModifiedDates = "kAssetsLastModifiedDates"

let kWPRequestImagesForLocalIdentifiers = "kWPRequestImagesForLocalIdentifiers"

let kWPRequestImageData = "kWPRequestImageData"

let kLocalIdentifier = "kLocalIdentifier"

let kNotifyWatchThatLibraryHasChanged = "kNotifyWatchThatLibraryHasChanged"
let kNotifyWatchThatImageHasChanged = "kNotifyWatchThatImageHasChanged"

let kDeleteWhenTransfered = "kDeleteWhenTransfered"

let kAssedModificationDate = "kAssedModificationDate"



let kSelectedImagesLocalIdentifiers = "kSelectedImagesLocalIdentifiers"

func createTemporaryFilename(pathExtension:String) -> NSURL! {
    if let cache = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true).first {
        return NSURL(fileURLWithPath: cache, isDirectory: true).URLByAppendingPathComponent(NSUUID().UUIDString).URLByAppendingPathExtension(pathExtension)
    }
    return nil
}

