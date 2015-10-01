//
//  PhotoShareLayout.swift
//  PhotoShare
//
//  Created by Lauren Brown on 22/09/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class PhotoShareLayout: UICollectionViewLayout {

    var layoutAttributes = [String : UICollectionViewLayoutAttributes]()
    var contentSize = CGSizeZero
    
    var horizontalInset : CGFloat = 15.0
    var verticalInset : CGFloat = 15.0
    
    var minimumItemWidth : CGFloat = 100.0
    var maximumItemWidth: CGFloat = 150.0
    var itemHeight: CGFloat = 150.0
    var initialBuild = true
    
    override func prepareLayout() {
        super.prepareLayout()
        if initialBuild {

            horizontalInset = (collectionView!.frame.size.width / 20)
            verticalInset = (collectionView!.frame.size.width / 20) //same inset for horizontal as vertical
            minimumItemWidth = (collectionView!.frame.size.width / 4)
            maximumItemWidth = (collectionView!.frame.size.width / 2)
            itemHeight = (collectionView!.frame.size.height / 3)
            
            layoutAttributes = [String : UICollectionViewLayoutAttributes]()
            
            let path = NSIndexPath(forItem: 0, inSection: 0)
            let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withIndexPath: path)
            
            let headerHeight = CGFloat(itemHeight / 4)
            attributes.frame = CGRectMake(0, 0, collectionView!.frame.size.width, headerHeight)
            
            let headerKey = layoutKeyForHeaderPath(path)
            layoutAttributes[headerKey] = attributes
            
            let numberOfSections = collectionView!.numberOfSections()
            
            var yOffset = headerHeight
            
            for var section = 0; section < numberOfSections; section++ {
                
                let numberOfItems = collectionView!.numberOfItemsInSection(section)
                var xOffset = horizontalInset
                
                for var item = 0; item < numberOfItems; item++ {
                    
                    let indexPath = NSIndexPath(forItem: item, inSection: section)
                    let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                    
                    var itemSize = CGSizeZero
                    var increaseRow = false
                    
                    if self.collectionView!.frame.size.width - xOffset > maximumItemWidth * 1.5 {
                        
                        itemSize = randomItemSize()
                    } else {
                        
                        itemSize.width = collectionView!.frame.size.width - xOffset - horizontalInset
                        itemSize.height = itemHeight
                        increaseRow = true
                    }
                    
                    attributes.frame = CGRectIntegral(CGRectMake(xOffset, yOffset, itemSize.width, itemSize.height))
                    let key = layoutKeyForIndexPath(indexPath)
                    layoutAttributes[key] = attributes
                    
                    
                    
                    if increaseRow && !(item == numberOfItems - 1 && section == numberOfSections - 1) {
                        
                        yOffset += verticalInset
                        yOffset += itemHeight
                        xOffset = horizontalInset
                    }else {

                        xOffset += itemSize.width
                        xOffset += horizontalInset
                    }
                }
            }
            
            yOffset += itemHeight
            contentSize = CGSizeMake(collectionView!.frame.size.width, yOffset + verticalInset)
        }
    }
    
    func layoutKeyForIndexPath(path: NSIndexPath) -> String {
        return "\(path.section)_\(path.row)"
    }
    
    func layoutKeyForHeaderPath(path: NSIndexPath) -> String {
        return "s_\(path.section)_\(path.row)"
    }
    
    func randomItemSize() -> CGSize {
        return CGSize(width: getRandomWidth(), height: itemHeight)
    }
    
    func getRandomWidth() -> CGFloat {
        let range = UInt32(maximumItemWidth - minimumItemWidth + 1)
        let rand = Float(arc4random_uniform(range))
        return CGFloat(minimumItemWidth) + CGFloat(rand)
    }
    
    override func collectionViewContentSize() -> CGSize {
        return contentSize
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        let headerKey = layoutKeyForHeaderPath(indexPath)
        return layoutAttributes[headerKey]
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        
        let key = layoutKeyForIndexPath(indexPath)
        return layoutAttributes[key]
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        let predicate = NSPredicate { [unowned self] (evaluatedObject, bindings) -> Bool in
            
            let layoutAttribute = self.layoutAttributes[evaluatedObject as! String]
            
            return CGRectIntersectsRect(rect, layoutAttribute!.frame)
        }
        
        let dict = layoutAttributes as NSDictionary
        let keys = dict.allKeys as NSArray
        let matchingKeys = keys.filteredArrayUsingPredicate(predicate)
        let value = (dict.objectsForKeys(matchingKeys, notFoundMarker: NSNull()) as? [UICollectionViewLayoutAttributes])
        
        return value
        
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        
        return !CGSizeEqualToSize(newBounds.size, collectionView!.frame.size)
    }
    
    
}

class PinnedHeaderLayout : PhotoShareLayout {
    
    var headerHeight: CGFloat = CGFloat(150.0/4)
    
    override func prepareLayout() {
        super.prepareLayout()
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        initialBuild = !CGSizeEqualToSize(newBounds.size, collectionView!.frame.size)
        return true
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        var attributes = super.layoutAttributesForElementsInRect(rect)
        
        if attributes != nil {
            let offset = collectionView?.contentOffset
            
            
            for attrs in attributes! {
                if attrs.representedElementKind == nil {
                    let indexPath        = NSIndexPath(forItem: 0, inSection: attrs.indexPath.section)
                    let layoutAttributes = self.layoutAttributesForSupplementaryViewOfKind(UICollectionElementKindSectionHeader, atIndexPath: indexPath)
                    
                    attributes!.append(layoutAttributes!)
                }
            }
            
            for attrs in attributes! {
                if attrs.representedElementKind == nil {
                    continue
                }
                
                if attrs.representedElementKind == UICollectionElementKindSectionHeader {
                    
                    var headerRect = attrs.frame
                    headerRect.size.height = headerHeight
                    headerRect.origin.y = offset!.y
                    attrs.frame = headerRect
                    attrs.zIndex = 1024
                    break
                }
            }
            return attributes
        }
        return nil
    }
}

