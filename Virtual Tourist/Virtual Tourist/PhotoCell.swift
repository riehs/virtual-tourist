//
//  PhotoCell.swift
//  Virtual Tourist
//
//  Created by Daniel Riehs on 8/18/15.
//  Copyright (c) 2015 Daniel Riehs. All rights reserved.
//

import UIKit

//This subclass is necessary because outlets cannot be connected to repeating content.
class PhotoCell: UICollectionViewCell {

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
}
