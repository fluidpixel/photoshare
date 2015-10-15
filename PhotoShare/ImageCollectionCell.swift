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
    
    @IBOutlet var favourite: UILabel!
    @IBOutlet weak var selectedTick: UIImageView!
    
    var localIdentifier:String = ""

    override func prepareForReuse() {
        self.localIdentifier = ""
        self.CellImage.image = nil
        
        self.selected = false
    }
    
    override var selected:Bool {
        didSet {
            if self.selected {
                self.selectedTick.hidden = false
//                self.layer.borderWidth = 2.0
//                self.layer.borderColor = UIColor.greenColor().CGColor
            }
            else {
                self.selectedTick.hidden = true
                self.layer.borderColor = UIColor.clearColor().CGColor
            }
        }
    }

}

class PhotoShareReusableView : UICollectionReusableView {
    
    
    @IBOutlet weak var commentLabel: UILabel!
}


