//
//  Here_s_Hingham_App.swift
//  Here's Hingham!
//
//  Created by Cameron Conway on 4/21/25.
//

import SwiftUI
import SwiftData
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import GoogleMaps

class AppDelegate: NSObject, UIApplicationDelegate {
  @EnvironmentObject var authenticationViewModel: AuthenticationViewModel

  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(.accentColor)
    UIPageControl.appearance().pageIndicatorTintColor = UIColor(named: "AccentSecondary")
    
    return true
  }
  
  static var orientationLock = UIInterfaceOrientationMask.all
  static var orientationForImage = false

  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return AppDelegate.orientationLock 
  }
}


@main
struct Here_s_Hingham_App: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @StateObject private var areasViewModel = AreasViewModel()
  @StateObject private var placesViewModel = PlacesViewModel()
  @Environment(\.modelContext) private var modelContext
    
  var body: some Scene {
    WindowGroup {
      MainView()
        .environmentObject(areasViewModel)
        .environmentObject(placesViewModel)
    }
    .modelContainer(for: [SchemaV1.Place.self, SchemaV1.Area.self]) { result in
      do {
        Task {
          do {
            try await Auth.auth().signIn(withEmail: "support@cambuilt.com", password: "jyzdyc-Tukrig-tyhgy4")
            loadData()
          }
          catch {
            print(error)
          }
        }
      }
    }
  }
  
  func loadData() {
    let db = Firestore.firestore()
    @AppStorage("ShowSpecial") var showSpecial: Bool = true
              
    db.collection("HinghamArea").getDocuments { queryArea, err in
      @AppStorage("HomeArea") var home: Int = -1
      var area = SchemaV1.Area()
      area.name = "(none)"
      area.areaId = -1
      areasViewModel.addArea(area)
      
      if home == -1 {
        areasViewModel.homeArea = area
      }
      
      db.collection("HinghamPlace").getDocuments { queryPlace, err in
        for document in queryArea!.documents {
          let area = SchemaV1.Area()
          area.documentID = document.documentID
          area.areaId = document.get("areaId") as! Int
          area.centerCoordinateLat = document.get("centerCoordinateLat") as! Double
          area.centerCoordinateLng = document.get("centerCoordinateLng") as! Double
          area.desc = document.get("desc") as! String
          area.iconCoordinateLat = document.get("iconCoordinateLat") as! Double
          area.iconCoordinateLng = document.get("iconCoordinateLng") as! Double
          area.name = document.get("name") as! String
          area.shortName = document.get("shortName") as! String
          area.tilt = document.get("tilt") as! Int
          area.imageCount = document.get("imageCount") as! Int
          area.videoUrl = document.get("videoUrl") as! String
          areasViewModel.addArea(area)
          if home == area.areaId {
            areasViewModel.homeArea = area
          }
        }

        for document in queryPlace!.documents {
          let place = SchemaV1.Place()
          place.documentID = document.documentID
          
          if let name = document.get("name") as? String {
            place.name = name
            place.address = document.get("address") as! String
            place.archStyle = document.get("archStyle") as! String
            place.areaId = document.get("areaId") as! Int
            place.areaName = document.get("areaName") as! String
            place.desc = document.get("desc") as! String
            place.googleId = document.get("googleId") as! String
            place.googleRating = document.get("googleRating") as! Double
            place.googleReviews = document.get("googleReviews") as! Int
            place.googleUrl = document.get("googleUrl") as! String
            place.hinghamRatings = document.get("hinghamRatings") as! String
            place.updateHinghamRating()
            place.hinghamReviews = document.get("hinghamReviews") as! Int
            place.hours = document.get("hours") as! String
            place.iconSize = document.get("iconSize") as! Double
            place.imageCount = document.get("imageCount") as! Int
            place.likes = document.get("likes") as! Int
            place.locationLat = document.get("locationLat") as! Double
            place.locationLng = document.get("locationLng") as! Double
            place.menuUrl = document.get("menuUrl") as! String
            place.nickname = document.get("nickname") as! String
            place.notes = document.get("notes") as! String
            place.phone = document.get("phone") as! String
            place.shortName = document.get("shortName") as! String
            place.specials = document.get("specials") as! String
            place.specialNotes = document.get("specialNotes") as! String
            place.type = document.get("type") as! Int
            place.website = document.get("website") as! String
            place.yelpCategory = document.get("yelpCategory") as! String
            place.yelpId = document.get("yelpId") as! String
            place.yelpRating = document.get("yelpRating") as! Double
            place.yelpReviews = document.get("yelpReviews") as! Int
            place.yelpPrice = document.get("yelpPrice") as! String
            place.yelpUrl = document.get("yelpUrl") as! String
            place.estimatedValue = document.get("estimatedValue") as! String
            place.lotSize = document.get("lotSize") as! Double
            place.squareFeet = document.get("squareFeet") as! Int
            place.yearBuilt = document.get("yearBuilt") as! Int
            place.instagram = document.get("instagram") as! String
            place.videoUrl = document.get("videoUrl") as! String
            
            if place.areaId != 100 {
              placesViewModel.addPlace(place)
            }
            
            area = areasViewModel.areas.filter({ $0.areaId == place.areaId }).first ?? SchemaV1.Area()
            
            if imageNameIfSpecialIsToday(special: place.specials, showSpecial: showSpecial) != "" {
              area.specialCount += 1
            }
          }
        }
      }
    }

    let query = db.collection("HinghamTour").order(by: "name")
    
    query.getDocuments { queryTour, err in
      for document in queryTour!.documents {
        let tour = SchemaV1.Tour()
        tour.documentID = document.documentID
        tour.tourId = document.get("tourId") as! Int
        tour.name = document.get("name") as! String
        tour.desc = document.get("desc") as! String
        areasViewModel.addTour(tour)
      }
    }
    
    db.collection("HinghamTourPlace").getDocuments { queryTourPlace, err in
      for document in queryTourPlace!.documents {
        let tourPlace = SchemaV1.TourPlace()
        tourPlace.documentID = document.documentID
        tourPlace.tourId = document.get("tourId") as! Int
        tourPlace.placeDocId = document.get("placeDocId") as! String
        tourPlace.name = document.get("name") as! String
        tourPlace.notes = document.get("notes") as! String
        placesViewModel.addTourPlace(tourPlace)
      }
    }
    
    let videoQuery = db.collection("HinghamVideo").order(by: "name")
    
    videoQuery.getDocuments { queryVideo, err in
      for document in queryVideo!.documents {
        let video = SchemaV1.Video()
        video.documentID = document.documentID
        video.name = document.get("name") as! String
        video.youtubeId = document.get("youtubeId") as! String
        areasViewModel.addVideo(video)
      }
    }
  }
}

struct GroceryProduct: Codable {
    var name: String
    var points: Int
    var description: String?
}

extension String {
    var isNumber: Bool {
      return self.replacingOccurrences(of: ",", with: "").range(
            of: "^[0-9]*$",
            options: .regularExpression) != nil && self != ""
    }
}

