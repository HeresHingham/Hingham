//
//  AreasViewModel.swift
//  Here's Hingham!
//
//  Created by Cameron Conway on 4/28/25.
//

import Foundation
import MapKit
import SwiftUI
import SwiftData
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import AVKit
import YouTubePlayerKit
import YouTubeiOSPlayerHelper

class AreasViewModel: ObservableObject {
  @EnvironmentObject private var placesViewModel: PlacesViewModel
  @Published var mapCameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
  @Published var zoom: Double = 0.0025
  @Published var areas: [SchemaV1.Area] = []
  @Published var tours: [SchemaV1.Tour] = []
  @Published var videos: [SchemaV1.Video] = []
  @Published var previewArea = SchemaV1.Area()
  @Published var selectedArea: SchemaV1.Area = SchemaV1.Area() {
    didSet {
      let span = MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom)
      if selectedArea.areaId > -1 {
        mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: selectedArea.centerCoordinates, span: span))
      } else {
        mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.22527,longitude: -70.88028), span: span))
      }
      updateRegion(mapCameraPosition)
    }
  }
  @Published var areaImageUrl = ""
  @Published var homeArea: SchemaV1.Area = SchemaV1.Area()
  @Published var selectedTour: SchemaV1.Tour = SchemaV1.Tour()
  @Published var centerCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
  @Published var showWatermark = true
  @Published var visible = true
  @Published var firstScreenVisible = true
  @Published var distance: Double = 0.0
  @Published var imagePath = ""
  @Published var imageCount = 0
  @Published var showCardView = false
  @Published var showAddToBucketList = false
  @Published var iconResizePercent: Double = 0.0
  @Published var satelliteMapStyle = MapStyle.imagery(elevation: .realistic)
  @Published var standardMapStyle = MapStyle.standard(pointsOfInterest: .including([]))
  @Published var previewHeightMultiple = 0.75
  @Published var ytPlayerView = YTPlayerView()
  @Published var statusObserver: NSKeyValueObservation?
  @Published var scrollItemId = 0
  @Published var iconAltitudeMaximum: Int = 6000
  @Published var loadingPlaces = false
  @Published var loadingTour = true
  @Published var imagery3DMode = false
  
  @Published var placeFilter: PlaceFilter = .None {
    didSet {
      let db = Firestore.firestore()
      
      for area in areas {
        db.collection("HinghamPlace").whereField("areaId", isEqualTo: area.areaId).whereField("type", in: [self.placeFilter.rawValue]).getDocuments { queryPlace, err in
          if queryPlace!.documents.count > 0 {
            switch self.placeFilter {
            case .Dining:
              area.iconImage = "fork.knife.circle.fill"
            case .Shopping, .Clothing, .Pharmacy, .Salon:
              area.iconImage = "handbag.circle.fill"
            case .Historic:
              area.iconImage = "house.circle.fill"
            case .Coffee:
              area.iconImage = "cup.and.saucer.circle.fill"
            case .Park:
              area.iconImage = "tree.circle.fill"
            default:
              area.iconImage = "map.circle.fill"
            }
          } else {
            area.iconImage = "map.circle.fill"
          }
        }
      }
    }
  }

  let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
  
  public func addArea(_ area: SchemaV1.Area) {
    areas.append(area)
  }
  
  public func addTour(_ tour: SchemaV1.Tour) {
    tours.append(tour)
  }
  
  public func addVideo(_ video: SchemaV1.Video) {
    videos.append(video)
  }
  
  public func updateRegion(_ mapCameraPosition: MapCameraPosition) {
    withAnimation(.easeInOut) {
      self.mapCameraPosition = mapCameraPosition
    }
  }
  
  public func updateAddToBucketlist(_ documentID: String) {
    @AppStorage("BucketList") var bucketList: String = ""
    let bucketListArray = bucketList.components(separatedBy: ",")   
    showAddToBucketList = !bucketListArray.contains(documentID)
  }
  
  public func isBucketPointList(area: SchemaV1.Area) -> Bool {
    return area.shortName == "World's End" || area.shortName == "More-Brewer" || area.shortName == "Turkey Hill"
  }
  
  public func isPlaceBucketPointList(place: SchemaV1.Place) -> Bool {
    return place.name == "Iron Horse Statue" || place.name == "No Noise Hingham"
  }
  
  public func firstScrollItemType(place: SchemaV1.Place) -> String {
    if scrollItemId == 0 {
      if isPlaceBucketPointList(place: place) {
        if place.videoUrl == "" {
          return "firstBucket•"
        } else {
          return "firstBucket•Video"
        }
      } else if place.name == "" && isBucketPointList(area: selectedArea) {
        if selectedArea.videoUrl == "" {
          return "firstBucket•"
        } else {
          return "firstBucket•Video"
        }
      } else {
        return ""
      }
    } else {
      return ""
    }
  }
  
  public func getImageUrl(placeName: String) -> String {
    var imageUrl = ""
    var path = selectedArea.shortName
    
    if areaImageUrl == "" {
      if visible == true || placeName == "" {
        imageUrl = (path == "" ? "Square" : selectedArea.shortName) + "/Area/0"
      } else {
        path = selectedArea.shortName == "" ? "tour" : selectedArea.shortName
        let placeImage = "/" + placeName + "/0"
        imageUrl = path + placeImage
        
        if UIImage(named: imageUrl) != nil {
          return imageUrl
        } else if UIImage(named: "Glad Tidings Plain" + placeImage) != nil {
          return "Glad Tidings Plain" + placeImage
        } else if UIImage(named: "West Hingham" + placeImage) != nil {
          return "West Hingham" + placeImage
        } else if UIImage(named: "Liberty Plain" + placeImage) != nil {
          return "Liberty Plain" + placeImage
        } else if UIImage(named: "Square" + placeImage) != nil {
          return "Square" + placeImage
        } else if UIImage(named: "Lincoln" + placeImage) != nil {
          return "Lincoln" + placeImage
        } else if UIImage(named: "Crow Point" + placeImage) != nil {
          return "Crow Point" + placeImage
        } else if UIImage(named: "Turkey Hill" + placeImage) != nil {
          return "Turkey Hill" + placeImage
        } else if UIImage(named: "East" + placeImage) != nil {
          return "East" + placeImage
        } else if UIImage(named: "Center" + placeImage) != nil {
          return "Center" + placeImage
        } else if UIImage(named: "Shipyard" + placeImage) != nil {
          return "Shipyard" + placeImage
        } else if UIImage(named: "Harbor" + placeImage) != nil {
          return "Harbor" + placeImage
        } else if UIImage(named: "World's End" + placeImage) != nil {
          return "World's End" + placeImage
        } else if UIImage(named: "More-Brewer" + placeImage) != nil {
          return "More-Brewer" + placeImage
        }
      }
    } else {
      imageUrl = areaImageUrl
    }
    
    return imageUrl
  }
  
  func showArea(_ area: SchemaV1.Area) {
    if area.imageCount == 0 {
      var imageCounter = 0
      while UIImage(named: ("\(area.shortName)/Area/\(imageCounter)")) != nil {
        imageCounter += 1
      }
      area.imageCount = imageCounter
    }
  }
  
  func zoomIn(_ zoom:Double) {
    updateRegion(MapCameraPosition.region(MKCoordinateRegion(center: centerCoordinate, span: MKCoordinateSpan(latitudeDelta: zoom, longitudeDelta: zoom))))
  }  
}

