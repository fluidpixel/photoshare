//
//  ImageCollectionCell.swift
//  PhotoShare
//
//  Created by Lauren Brown on 21/09/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import UIKit

class ImageCollectionCell: UICollectionViewCell {
    
    @IBOutlet weak var CellImage: UIImageView!
    
    var localIdentifier:String = ""

    override func prepareForReuse() {
        self.localIdentifier = ""
        self.CellImage.image = nil
        
        self.selected = false
    }
}

class PhotoShareReusableView : UICollectionReusableView {
    
    
    @IBOutlet weak var commentLabel: UILabel!
}


