//
//  DownloadPhotos.swift
//  Virtual Tourist
//
//  Created by Daniel Riehs on 4/2/15.
//  Copyright (c) 2015 Daniel Riehs. All rights reserved.
//

import CoreData
import UIKit

class DownloadPhotos {

	//Useful for saving data into the Core Data context.
	var sharedContext: NSManagedObjectContext {
		return CoreDataStackManager.sharedInstance().managedObjectContext!
	}

	//Constants:
	let BASE_URL = "https://api.flickr.com/services/rest/"
	let METHOD_NAME = "flickr.photos.search"
	let API_KEY = "SET API KEY HERE."
	let EXTRAS = "url_m"
	let SAFE_SEARCH = "1"
	let DATA_FORMAT = "json"
	let NO_JSON_CALLBACK = "1"
	let PER_PAGE = "21"
	let BOUNDING_BOX_HALF_WIDTH = 1.0
	let BOUNDING_BOX_HALF_HEIGHT = 1.0
	let LAT_MIN = -90.0
	let LAT_MAX = 90.0
	let LON_MIN = -180.0
	let LON_MAX = 180.0


	//The Flickr API requires that locations are stated as boxes rather than points.
	func createBoundingBoxString(_ latitude: Double, longitude: Double) -> String {
		return "\(longitude - BOUNDING_BOX_HALF_WIDTH),\(latitude - BOUNDING_BOX_HALF_HEIGHT),\(longitude + BOUNDING_BOX_HALF_WIDTH),\(latitude + BOUNDING_BOX_HALF_HEIGHT)"
	}


	//This function determines how many pages of relevant photos are available.
	func getImageFromFlickrBySearch(_ photoAlbum: PhotoCollectionView, pin: Pin, completionHandler: @escaping (_ success: Bool, _ errorString: String?) -> Void) {

		let methodArguments = [
			"method": METHOD_NAME,
			"api_key": API_KEY,
			"bbox": createBoundingBoxString(pin.latitude, longitude: pin.longitude),
			"safe_search": SAFE_SEARCH,
			"extras": EXTRAS,
			"format": DATA_FORMAT,
			"nojsoncallback": NO_JSON_CALLBACK,
			"per_page": PER_PAGE
		]

		let session = URLSession.shared
		let urlString = BASE_URL + escapedParameters(methodArguments as [String : AnyObject])
		let url = URL(string: urlString)!
		let request = URLRequest(url: url)

		let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in
			if let error = downloadError {
				completionHandler(false, "Could not complete the request \(error)")
			} else {

				let parsedResult = (try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)) as! NSDictionary

				if let photosDictionary = parsedResult.value(forKey: "photos") as? [String:AnyObject] {

					if let totalPages = photosDictionary["pages"] as? Int {

						//A random page of photos is selected.
						let pageLimit = min(totalPages, 40)
						let randomPage = Int(arc4random_uniform(UInt32(pageLimit) + 1))

						//A function is called that only fetches photos for the selected page.
						self.getImageFromFlickrBySearchWithPage(methodArguments as [String : AnyObject], pageNumber: randomPage, photoAlbum: photoAlbum, pin: pin) { (success, errorString) in
							if success {
								completionHandler(true, nil)
							} else {
								completionHandler(false, errorString)
							}
						}

					} else {
						completionHandler(false, "Cannot find key 'pages' in \(photosDictionary)")
					}
				} else {
					completionHandler(false, "Cannot find key 'photos' in \(parsedResult)")
				}
			}
		}) 

		task.resume()
	}


	//Fetches photos from Flickr from the randomly-selected page.
	func getImageFromFlickrBySearchWithPage(_ methodArguments: [String : AnyObject], pageNumber: Int, photoAlbum: PhotoCollectionView, pin: Pin, completionHandler: @escaping (_ success: Bool, _ errorString: String?) -> Void) {

		//Add the page to the method's arguments
		var withPageDictionary = methodArguments
		withPageDictionary["page"] = pageNumber as AnyObject?

		let session = URLSession.shared
		let urlString = BASE_URL + escapedParameters(withPageDictionary)
		let url = URL(string: urlString)!
		let request = URLRequest(url: url)

		let task = session.dataTask(with: request, completionHandler: {data, response, downloadError in
			if let error = downloadError {
				completionHandler(false, "Could not complete the request \(error)")
			} else {

				let parsedResult = (try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments)) as! NSDictionary

				if let photosDictionary = parsedResult.value(forKey: "photos") as? [String:AnyObject] {
					var totalPhotosVal = 0
					if let totalPhotos = photosDictionary["total"] as? String {
						totalPhotosVal = (totalPhotos as NSString).integerValue
					}

					if totalPhotosVal > 21 {
						totalPhotosVal = 21
					}
					photoAlbum.photoCount = totalPhotosVal

					if totalPhotosVal > 0 {

						if let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] {

							for photoCount in 0 ..< totalPhotosVal {
								let photoDictionary = photosArray[photoCount] as [String: AnyObject]
								var imageUrlString = photoDictionary["url_m"] as? String

								//The "_q" filename suffix downloads small square photos from Flickr.
								imageUrlString = imageUrlString!.replacingOccurrences(of: ".jpg", with: "_q.jpg")

								if let imageURL = URL(string: imageUrlString!) {

									if let imageData = try? Data(contentsOf: imageURL) {

										DispatchQueue.main.async(execute: {

											let fileManager = FileManager.default
											let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
											let filePathToWrite = "\(path)/\(imageURL.lastPathComponent)"

											//If the photo is successfully saved to the Documents folder, a Photo object is created and saved to the pin.
											if  fileManager.createFile(atPath: filePathToWrite, contents: imageData, attributes: nil) {
												Photo(imageFileName: imageURL.lastPathComponent, context: self.sharedContext).pin = pin

												//Save photo to Core Data.
												CoreDataStackManager.sharedInstance().saveContext()

												//Refresh PhotoAlbumViewController so that the new photo is visible.
												photoAlbum.reloadData()
											}
										})

									} else {
										completionHandler(false, "Image does not exist at \(imageURL)")
									}
								} else {
									completionHandler(false, "Error")
								}
							}

							//All of the photos were successfully loaded.
							pin.loading = false
							completionHandler(true, nil)

						} else {
							completionHandler(false, "Cannot find key 'photo' in \(photosDictionary)")
						}
					} else {
						completionHandler(false, "No photos found.")
					}
				} else {
					completionHandler(false, "Cant find key 'photos' in \(parsedResult)")
				}
			}
		}) 

		task.resume()
	}


	/* Helper function: Given a dictionary of parameters, convert to a string for a url */
	func escapedParameters(_ parameters: [String : AnyObject]) -> String {

		var urlVars = [String]()

		for (key, value) in parameters {

			/* Make sure that it is a string value */
			let stringValue = "\(value)"

			/* FIX: Replace spaces with '+' */
			let replaceSpaceValue = stringValue.replacingOccurrences(of: " ", with: "+", options: NSString.CompareOptions.literal, range: nil)

			/* Append it */
			urlVars += [key + "=" + "\(replaceSpaceValue)"]
		}

		return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
	}


	class func sharedInstance() -> DownloadPhotos {
		struct Singleton {
			static var sharedInstance = DownloadPhotos()
		}
		return Singleton.sharedInstance
	}
	
}
