//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Daniel Riehs on 4/2/15.
//  Copyright (c) 2015 Daniel Riehs. All rights reserved.
//

import MapKit
import CoreData

//Make Pin available to Objective-C code. (Necessary for Core Data.)
@objc(Pin)

//Make Pin a subclass of NSManagedObject. (Necessary for Core Data.)
class Pin: NSManagedObject, MKAnnotation {

	//Useful for saving data into the Core Data context.
	var sharedContext: NSManagedObjectContext {
		return CoreDataStackManager.sharedInstance().managedObjectContext!
	}

	//Promoting these five properties to Core Data attributes by prefixing them with @NSManaged.
	@NSManaged var latitude: Double
	@NSManaged var longitude: Double
	@NSManaged var title: String?
	@NSManaged var photos: [Photo]
	@NSManaged var loading: Bool

	//The location must be a computed property because CLLocationCoordinate2D cannot be stored in Core Data.
	var coordinate: CLLocationCoordinate2D {
			return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}


	//The standard Core Data init method.
	override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		super.init(entity: entity, insertInto: context)
	}


	//Load pins from Core Data.
	func fetchAllPhotos() -> [Pin] {
		let error: NSErrorPointer? = nil
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
		let results: [AnyObject]?
		do {
			results = try sharedContext.fetch(fetchRequest)
		} catch let error1 as NSError {
			error??.pointee = error1
			results = nil
		}

		if error != nil {
			print("Error in fetchAllPins(): \(String(describing: error))")
		}

		return results as! [Pin]
	}


	//The init method needs to accept the shared context as one of its parameters.
	init(latitude: Double, longitude: Double, title: String, context: NSManagedObjectContext) {

		//The entity name here is the same as the entity name in the Model.xcdatamodeld file.
		let entity =  NSEntityDescription.entity(forEntityName: "Pin", in: context)!

		super.init(entity: entity, insertInto: context)

		self.latitude = latitude
		self.longitude = longitude
		self.title = title

		//The loading property is set to true so that the PhotoAlbumViewController knows to fetch a new collection of photos.
		loading = true

		CoreDataStackManager.sharedInstance().saveContext()
	}
}

