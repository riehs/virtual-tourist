//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Daniel Riehs on 4/2/15.
//  Copyright (c) 2015 Daniel Riehs. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {


	@IBOutlet weak var mapView: MKMapView!

	var pins = [Pin]()
	var map = [Map]()

	//Useful for saving data into the Core Data context.
	var sharedContext: NSManagedObjectContext {
		return CoreDataStackManager.sharedInstance().managedObjectContext!
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		map = fetchMap()
		if map.count == 0 {
			map.append(Map(latitude: -3.831239, longitude: -78.183406, altitude: 50000000, context: sharedContext))
		}

		//Sets the map zoom.
		mapView?.camera.altitude = map[0].altitude

		//Sets the center of the map.
		mapView?.centerCoordinate = CLLocationCoordinate2D(latitude: map[0].latitude, longitude: map[0].longitude)

		mapView.delegate = self

		pins = fetchAllPins()

		for pin in pins {
			mapView.addAnnotation(pin)
		}

		let longPress = UILongPressGestureRecognizer(target: self, action: "action:")
		longPress.minimumPressDuration = 1.0
		longPress.allowableMovement = 0.0
		mapView.addGestureRecognizer(longPress)
	}


	func action(gestureRecognizer:UIGestureRecognizer) {
		if gestureRecognizer.enabled {
			gestureRecognizer.enabled = false

			let touchPoint = gestureRecognizer.locationInView(mapView)

			let newCoord: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)

			var title = ""

			//Reverse geocode to get location name.
			CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: newCoord.latitude, longitude: newCoord.longitude), completionHandler: {(placemarks, error) -> Void in

				if error != nil {
					title = "Reverse geocoder failed with error" + error!.localizedDescription
				}
				if placemarks!.count > 0 {
					let pm = placemarks!.first
					if pm!.locality != nil {
						title = pm!.locality!
					} else {
						title = "Unknown Location"
					}
				} else {
					title = "Problem with the data received from geocoder."
				}

				//Create pin and place on map.
				let pin = Pin(latitude: newCoord.latitude, longitude: newCoord.longitude, title: title, context: self.sharedContext)
				self.pins.append(pin)

				CoreDataStackManager.sharedInstance().saveContext()

				self.mapView.addAnnotation(pin)

				gestureRecognizer.enabled = true
			})
		}
	}


	//Sends the the pin that was tapped on to the PhotoAlbumViewController.
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
			let photoAlbumVC:PhotoAlbumViewController = segue.destinationViewController as! PhotoAlbumViewController
			photoAlbumVC.pin = sender as! Pin
	}


	//Segues to the Photo Album when the annotation info box is tapped.
	func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		performSegueWithIdentifier("goToPictures", sender: view.annotation)
	}


	//Adds a "callout" to the annotation info box so that it can be tapped to access the photos.
	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MapAnnotation")
		view.animatesDrop = true
		view.canShowCallout = true
		view.calloutOffset = CGPoint(x: -5, y: 5)
		view.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure) as UIView
		return view
	}


	//Loads the map center and zoom level from Core Data.
	func fetchMap() -> [Map] {
		let error: NSErrorPointer = nil
		let fetchRequest = NSFetchRequest(entityName: "Map")
		let results: [AnyObject]?
		do {
			results = try sharedContext.executeFetchRequest(fetchRequest)
		} catch let error1 as NSError {
			error.memory = error1
			results = nil
		}

		if error != nil {
			print("Error in fetchMap(): \(error)")
		}

		return results as! [Map]
	}


	//Loads pins from Core Data.
	func fetchAllPins() -> [Pin] {
		let error: NSErrorPointer = nil
		let fetchRequest = NSFetchRequest(entityName: "Pin")
		let results: [AnyObject]?
		do {
			results = try sharedContext.executeFetchRequest(fetchRequest)
		} catch let error1 as NSError {
			error.memory = error1
			results = nil
		}

		if error != nil {
			print("Error in fetchAllPins(): \(error)")
		}

		return results as! [Pin]
	}


	//Saves the map state to Core Data whenever the location or zoom is changed.
	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool){
		map[0].latitude = mapView.centerCoordinate.latitude
		map[0].longitude = mapView.centerCoordinate.longitude
		map[0].altitude = mapView.camera.altitude
		CoreDataStackManager.sharedInstance().saveContext()
	}


	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
