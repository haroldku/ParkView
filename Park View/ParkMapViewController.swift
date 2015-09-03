//
//  ParkMapViewController.swift
//  Park View
//
//  Created by Niv Yahel on 2014-11-09.
//  Copyright (c) 2014 Chris Wagner. All rights reserved.
//

import UIKit
import MapKit

enum MapType: Int {
  case Standard = 0
  case Hybrid
  case Satellite
}

class ParkMapViewController: UIViewController {
  
  @IBOutlet var mapView: MKMapView!
  @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
  
  var selectedOptions = [MapOptionsType]()
  var park = Park(filename: "MagicMountain")
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let latDelta = park.overlayTopLeftCoordinate.latitude - park.overlayBottomRightCoordinate.latitude
    
    let span = MKCoordinateSpanMake(fabs(latDelta), 0.0)
    
    let region = MKCoordinateRegionMake(park.midCoordinate, span)
    mapView.region = region
  }
  
  func loadSelectedOptions() {
    mapView.removeAnnotations(mapView.annotations)
    mapView.removeOverlays(mapView.overlays)
    
    for option in selectedOptions {
        switch (option) {
        case .MapOverlay:
            addOverlay()
        case .MapPins:
            addAttractionPins()
        case .MapRoute:
            addRoute()
        case .MapBoundary:
            addBoundary()
        default:
            break;
        }
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let optionsViewController = segue.destinationViewController as! MapOptionsViewController
    optionsViewController.selectedOptions = selectedOptions
  }
  
  @IBAction func closeOptions(exitSegue: UIStoryboardSegue) {
    let optionsViewController = exitSegue.sourceViewController as! MapOptionsViewController
    selectedOptions = optionsViewController.selectedOptions
    self.loadSelectedOptions()
  }
  
  @IBAction func mapTypeChanged(sender: AnyObject) {
    let mapType = MapType(rawValue: mapTypeSegmentedControl.selectedSegmentIndex)
    switch(mapType!) {
    case .Standard:
        mapView.mapType = MKMapType.Standard
    case .Hybrid:
        mapView.mapType = MKMapType.Hybrid  
    case .Satellite:
        mapView.mapType = MKMapType.Satellite
    }
  }
  
    func addBoundary() {
        let polygon = MKPolygon(coordinates: &park.boundary, count: park.boundaryPointsCount)
        mapView.addOverlay(polygon)
    }
    
  func addOverlay() {
    let overlay = ParkMapOverlay(park: park)
    mapView.addOverlay(overlay)
    
    
    
    }
    
   func addAttractionPins() {
        let filePath = NSBundle.mainBundle().pathForResource("MagicMountainAttractions", ofType: "plist")
        let attractions = NSArray(contentsOfFile: filePath!)
        for attraction in attractions! {
            let point = CGPointFromString(attraction["location"] as! String)
            let coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(point.x), CLLocationDegrees(point.y))
            let title = attraction["name"] as! String
            let typeRawValue = (attraction["type"] as! String).toInt()!
            let type = AttractionType(rawValue: typeRawValue)
            let subtitle = attraction["subtitle"] as! String
            let annotation = AttractionAnnotation(coordinate: coordinate, title: title, subtitle: subtitle, type: type!)
            mapView.addAnnotation(annotation)
        }
    }
    
    func addRoute() {
    let thePath = NSBundle.mainBundle().pathForResource("EntranceToGoliathRoute", ofType: "plist")
    let pointsArray = NSArray(contentsOfFile: thePath!)
    
    let pointsCount = pointsArray!.count
    
    var pointsToUse: [CLLocationCoordinate2D] = []
    
    for i in 0...pointsCount-1 {
        let p = CGPointFromString(pointsArray![i] as! String)
        pointsToUse += [CLLocationCoordinate2DMake(CLLocationDegrees(p.x), CLLocationDegrees(p.y))]
    }
    
    let myPolyline = MKPolyline(coordinates: &pointsToUse, count: pointsCount)
    
    mapView.addOverlay(myPolyline)
    }

}

// MARK: - Map View delegate

extension ParkMapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) ->MKOverlayRenderer! {
        if overlay is ParkMapOverlay {
            let magicMountainImage = UIImage(named: "overlay_park")
            let overlayView = ParkMapOverlayView(overlay: overlay, overlayImage: magicMountainImage!)
            
            return overlayView
        }else if overlay is MKPolyline {
            let lineView = MKPolylineRenderer(overlay: overlay)
            lineView.strokeColor = UIColor.greenColor()
            
            return lineView
        }else if overlay is MKPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.strokeColor = UIColor.magentaColor()
            
            return polygonView
        }
        
        return nil
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let annotationView = AttractionAnnotationView(annotation: annotation, reuseIdentifier: "Attraction")
        annotationView.canShowCallout = true
        return annotationView
    }
}
