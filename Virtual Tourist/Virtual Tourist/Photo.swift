//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Daniel Riehs on 4/2/15.
//  Copyright (c) 2015 Daniel Riehs. All rights reserved.
//

import UIKit
import CoreData

//Make Photo available to Objective-C code. (Necessary for Core Data.)
@objc(Photo)

//Make Photo a subclass of NSManagedObject. (Necessary for Core Data.)
class Photo: NSManagedObject {

	//Promoting these two properties to Core Data attributes by prefixing them with @NSManaged.
	@NSManaged var imageFileName: String
	@NSManaged var pin: Pin?


	var image: UIImage {

		return UIImage(contentsOfFile: getFilePath(imageFileName))!
	}


	//The standard Core Data init method.
	override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		super.init(entity: entity, insertInto: context)
	}


	//The init method needs to accept the shared context as one of its parameters.
	init(imageFileName: String, context: NSManagedObjectContext) {

		//The entity name here is the same as the entity name in the Model.xcdatamodeld file.
		let entity =  NSEntityDescription.entity(forEntityName: "Photo", in: context)!

		super.init(entity: entity, insertInto: context)

		self.imageFileName = imageFileName
	}


	//Only the filename is stored in Core Data, because the location of the Documents folder changes when the app is re-run in the Xcode simulator.
	func getFilePath(_ imageFileName: String) -> String {

		let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] 
		return "\(dirPath)/\(imageFileName)"
	}


	//This function is called when the photo is deleted from the Core Data context.
	override func prepareForDeletion() {

		//Delete the photo from the Documents folder.
		let fileManager = FileManager.default
		do {
			try fileManager.removeItem(atPath: getFilePath(imageFileName))
		} catch _ {
		}
	}
}
