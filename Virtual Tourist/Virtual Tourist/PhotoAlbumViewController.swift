//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Daniel Riehs on 4/2/15.
//  Copyright (c) 2015 Daniel Riehs. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController:  UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

	var pin: Pin!

	@IBOutlet weak var mapView: MKMapView!

	@IBOutlet weak var collectionView: PhotoCollectionView!

	@IBOutlet weak var newCollectionButton: UIBarButtonItem!

	@IBAction func getNewCollection(sender: AnyObject) {
		getNewCollection()
	}


	//Useful for deleting data from Core Data context.
	var sharedContext: NSManagedObjectContext {
		return CoreDataStackManager.sharedInstance().managedObjectContext!
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		//Sets the map zoom.
		mapView.camera.altitude = 500000;

		//Sets the center of the map.
		mapView.centerCoordinate = pin.coordinate

		mapView.addAnnotation(pin)
		mapView.selectAnnotation(pin, animated: true)

		//Fetches photos.
		if pin.loading {

			//Disables "New Collection" button while photos are loading.
			newCollectionButton.enabled = false
			DownloadPhotos.sharedInstance().getImageFromFlickrBySearch(collectionView, pin: pin) { (success, errorString) in
				if success {
					dispatch_async(dispatch_get_main_queue(), {
						self.newCollectionButton.enabled = true
					})

				} else {
				self.errorAlert("Error", error: errorString!)
				}
			}
		}
	}


	//Deletes existing photos, and fetches a new collection.
	func getNewCollection() {

		pin.loading = true
		for photo in pin.photos {
			sharedContext.deleteObject(photo as NSManagedObject)
		}

		//Disables "New Collection" button while photos are loading.
		newCollectionButton.enabled = false
		DownloadPhotos.sharedInstance().getImageFromFlickrBySearch(collectionView, pin: pin) { (success, errorString) in
			if success {
				dispatch_async(dispatch_get_main_queue(), {
					self.newCollectionButton.enabled = true
				})
			} else {
				dispatch_async(dispatch_get_main_queue(), {
					self.errorAlert("Error", error: errorString!)
					self.newCollectionButton.enabled = true
				})
			}
		}
	}


	//Creates an Alert-style error message.
	func errorAlert(title: String, error: String) {
		let controller: UIAlertController = UIAlertController(title: title, message: error, preferredStyle: .Alert)
		controller.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
		presentViewController(controller, animated: true, completion: nil)
	}


	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		// Lay out the collection view so that cells take up 1/3 of the width,
		// with no space in between.
		let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
		layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
		layout.minimumLineSpacing = 0
		layout.minimumInteritemSpacing = 0

		let width = floor(collectionView.frame.size.width/3)
		layout.itemSize = CGSize(width: width, height: width)
		collectionView.collectionViewLayout = layout
	}


	func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		if pin.photos.count > self.collectionView.photoCount {
			return pin.photos.count
		} else {
			return self.collectionView.photoCount
		}
	}


	func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell{

		let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! PhotoCell

		var photo: UIImage
		
		//Any cells with an index greater than the photo count (+1) must still be loading.
		if ((indexPath.item + 1) <= pin.photos.count) {
			cell.activityIndicator.hidden = true
			photo = pin.photos[indexPath.item].image
		} else {
			cell.activityIndicator.hidden = false
			photo = UIImage(named: "Loading")!
		}

		cell.backgroundView = UIImageView(image: photo)

		return cell
	}


	//Photos are deleted when users tap them.
	func collectionView(tableView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
	{

		//Delete the photo from the Core Data context.
		sharedContext.deleteObject(pin.photos[indexPath.item] as NSManagedObject)

		self.collectionView.photoCount -= 1
		CoreDataStackManager.sharedInstance().saveContext()

		//Delete the photo from the tableView.
		tableView.deleteItemsAtIndexPaths([indexPath])
	}
}
