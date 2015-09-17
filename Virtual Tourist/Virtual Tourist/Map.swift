//
//  Map.swift
//  Virtual Tourist
//
//  Created by Daniel Riehs on 8/16/15.
//  Copyright (c) 2015 Daniel Riehs. All rights reserved.
//

import CoreData

//Make Map available to Objective-C code. (Necessary for Core Data.)
@objc(Map)

//Make Map a subclass of NSManagedObject. (Necessary for Core Data.)
class Map: NSManagedObject {


	//Promoting these four properties to Core Data attributes by prefixing them with @NSManaged.
	@NSManaged var latitude: Double
	@NSManaged var longitude: Double
	@NSManaged var altitude: Double


	//The standard Core Data init method.
	override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
		super.init(entity: entity, insertIntoManagedObjectContext: context)
	}


	//The init method needs to accept the shared context as one of its parameters.
	init(latitude: Double, longitude: Double, altitude: Double, context: NSManagedObjectContext) {

		//The entity name here is the same as the entity name in the Model.xcdatamodeld file.
		let entity =  NSEntityDescription.entityForName("Map", inManagedObjectContext: context)!

		super.init(entity: entity, insertIntoManagedObjectContext: context)

		self.latitude = latitude
		self.longitude = longitude
		self.altitude = altitude
	}
}
