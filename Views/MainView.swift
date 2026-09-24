
//
//  MainView.swift
//  Here's Hingham!
//
//  Created by Cameron Conway on 8/21/25.•
//
import Foundation
import SwiftUI
import SwiftData
import MapKit
import GoogleMaps
import CoreLocation
import FirebaseFirestore
import AVKit
import YouTubePlayerKit
import YouTubeiOSPlayerHelper

struct MainView: View {
  @EnvironmentObject private var areasViewModel: AreasViewModel
  @EnvironmentObject private var placesViewModel: PlacesViewModel
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.openURL) private var openUrl
  @State private var position = MapCameraPosition.region(
    MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.22527,longitude: -70.88028), span: MKCoordinateSpan(latitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.11, longitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.11)))
  @State private var annotationOpacity: Double = 1.0
  @State private var paths: [String] = []
  @State private var showPlaceCard = false
  @State private var longPressCoordinate: CLLocationCoordinate2D?
  @State private var lookAroundScene: MKLookAroundScene?
  @State private var isShowingLookAroundViewer: Bool = false
  @State private var isLookAroundUnavailable: Bool = false
  @State private var isInitialView: Bool = true
  @State private var cameraIsChanging: Bool = false
  @State private var tabSelection: Int = 0
  @State private var currentPage: Int = 0
  @State private var skipAreaCard: Bool = false
  @State private var showHouses: Bool = true
  @State private var showSpecials: Bool = true
  @State private var showLabels: Bool = true
  @State private var homeAreaId: Int = -1
  @State private var homeArea: SchemaV1.Area = SchemaV1.Area()
  @State private var toasts: [Toast] = []
  @State private var mapStyle: MapStyle = MapStyle.standard(pointsOfInterest: .including([]))
  @State private var interactionModes: MapInteractionModes = [.all]
  @State private var imagery3DMode = false
  @ObservedObject var location: LocationManager = LocationManager()
  
  let maxWidth: CGFloat = 475
  let hinghamCoordinates: [CLLocationCoordinate2D] = [
    CLLocationCoordinate2D(latitude: 42.22471, longitude: -70.91455),
    CLLocationCoordinate2D(latitude: 42.15761, longitude: -70.92492),
    CLLocationCoordinate2D(latitude: 42.20098, longitude: -70.82721),
    CLLocationCoordinate2D(latitude: 42.21291, longitude: -70.84067),
    CLLocationCoordinate2D(latitude: 42.23961, longitude: -70.85329),
    CLLocationCoordinate2D(latitude: 42.24335, longitude: -70.84105),
    CLLocationCoordinate2D(latitude: 42.24448, longitude: -70.84124),
    CLLocationCoordinate2D(latitude: 42.24732, longitude: -70.84908),
    CLLocationCoordinate2D(latitude: 42.26032, longitude: -70.84453),
    CLLocationCoordinate2D(latitude: 42.25864, longitude: -70.84851),
    CLLocationCoordinate2D(latitude: 42.25956, longitude: -70.86733),
    CLLocationCoordinate2D(latitude: 42.26819, longitude: -70.86781),
    CLLocationCoordinate2D(latitude: 42.27471, longitude: -70.88119),
    CLLocationCoordinate2D(latitude: 42.26189, longitude: -70.91493),
    CLLocationCoordinate2D(latitude: 42.25432, longitude: -70.92095),
    CLLocationCoordinate2D(latitude: 42.25206, longitude: -70.93223),
    CLLocationCoordinate2D(latitude: 42.24428, longitude: -70.93127),
    CLLocationCoordinate2D(latitude: 42.22907, longitude: -70.92296),
    CLLocationCoordinate2D(latitude: 42.22624, longitude: -70.92421),
    CLLocationCoordinate2D(latitude: 42.22471, longitude: -70.91455)
  ]
  
  var body: some View {
    NavigationStack(path: $paths) {
      ZStack {
        if isShowingLookAroundViewer == true {
          LookAroundPreview(initialScene: lookAroundScene, allowsNavigation: true)
            .frame(width: UIScreen.main.bounds.width * 0.93, height: UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.size.height * 0.66 : UIScreen.main.bounds.height * 0.33)
            .cornerRadius(12)
            .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.height * 0.2 : UIScreen.main.bounds.height * 0.524)
            .zIndex(1.0)
            .overlay(alignment: .topTrailing) {
              Button {
                isShowingLookAroundViewer = false
              }
              label: {
                 Image(systemName: "xmark.circle.fill")
                  .font(.system(size: 32))
              }
              .foregroundColor(.white)
              .padding()
            }
        }
      
        if areasViewModel.visible == true && (homeAreaId == -1 || isInitialView == false) {
          areaMapLayer
        } else if areasViewModel.mapCameraPosition.region != nil {
          placeMapLayer
        }
      
        VStack {
          filterHScrollToolbar

          if (areasViewModel.visible == false && placesViewModel.isBucketPointList(place: placesViewModel.selectedPlace)) || (areasViewModel.visible == true && areasViewModel.isBucketPointList(area: areasViewModel.selectedArea) && areasViewModel.showCardView == true) {
            bucketPointImageSection
          }
          
          Spacer()
          
          if areasViewModel.showCardView == true {
            CardView(showPlaceDetail: $showPlaceCard, mapStyle: $mapStyle, imagery3DMode: $imagery3DMode, area: areasViewModel.selectedArea)
              .frame(minWidth: UIDevice.current.userInterfaceIdiom == .pad ? 550 : UIScreen.main.bounds.width * 0.93, minHeight: UIScreen.main.bounds.height * areasViewModel.previewHeightMultiple, maxHeight: UIScreen.main.bounds.height * areasViewModel.previewHeightMultiple)
              .shadow(color: .black.opacity(0.3), radius: 20)
              .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
              .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 20 : -10)
          }
        }
      }
      .navigationTitle("Here's Hingham")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          if areasViewModel.firstScreenVisible == false {
            Button {
              areasViewModel.iconAltitudeMaximum = 0
              areasViewModel.loadingPlaces = false
              areasViewModel.imagery3DMode = false
              imagery3DMode = false
              mapStyle = areasViewModel.standardMapStyle
              if showPlaceCard == true {
                showPlaceCard = false
                withAnimation(.easeInOut) {
                  areasViewModel.visible = false
                }
              } else {
                withAnimation(.easeInOut) {
                  placesViewModel.selectedPlace = SchemaV1.Place()
                  placesViewModel.visible = false
                  areasViewModel.visible = true
                  areasViewModel.distance = 0.0
                  areasViewModel.firstScreenVisible = true
                  areasViewModel.showCardView = false
                  areasViewModel.selectedTour = SchemaV1.Tour()
                  areasViewModel.iconResizePercent = 0.0
                  areasViewModel.placeFilter = .None
                  areasViewModel.selectedArea = areasViewModel.areas[0]
                  areasViewModel.selectedTour.tourId = -1
                }
              }
            } label:
            {
              Image(systemName: "chevron.left")
            }
          }
        }
        ToolbarItem(placement: .principal) {
          Image("AppToolbar")
            .resizable()
            .scaledToFit()
            .frame(height: 30)
        }
        ToolbarItem(placement: .navigationBarTrailing)  {
          ellipsisMenu
        }
      }
      .onAppear(perform: {
        @AppStorage("HomeArea") var home: Int = -1
        homeAreaId = home
        @AppStorage("SkipAreaCard") var skip: Bool = false
        skipAreaCard = skip
        @AppStorage("ShowHouses") var showHouse: Bool = true
        showHouses = showHouse
        @AppStorage("ShowSpecials") var showSpecial: Bool = true
        showSpecials = showSpecial
        @AppStorage("ShowLabels") var showLabel: Bool = true
        showLabels = showLabel
        @AppStorage("IconAltitudeMaximum") var iconAltitude = 6000
        areasViewModel.iconAltitudeMaximum = iconAltitude
        
        if home != -1 {
          let db = Firestore.firestore()
          db.collection("HinghamArea").whereField("areaId", isEqualTo: home).getDocuments { (querySnapshot, error) in
            if let error = error {
              print("Error getting documents: \(error.localizedDescription)")
              return
            }
            
            guard let document = querySnapshot?.documents.first else {
              print("No document found matching the condition")
              return
            }
            
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
            areasViewModel.selectedArea = area
            areasViewModel.firstScreenVisible = false
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
              withAnimation(.easeInOut) {
                isInitialView = false
                areasViewModel.showCardView = false
                areasViewModel.visible = false
              }
            }
          }
        }
      })
      .alert(isPresented: $isLookAroundUnavailable) {
        Alert(title: Text("Look Around"), message: Text("Look around is not available in this area."), dismissButton: .default(Text("OK")))
      }
    }
    .interactiveToast($toasts)
    .onAppear {
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
      areasViewModel.previewHeightMultiple = UIDevice.current.userInterfaceIdiom == .pad ? UIDevice.current.orientation == .portrait || UIDevice.current.orientation == .portraitUpsideDown ? 0.6 : 0.9 : 0.75
    }
  }
  
  func showToast(_ text: String, _ icon: String) {
    withAnimation(.spring) {
      let toast = Toast { id in self.ToastView(id, text, icon) }
        toasts.append(toast)
    }
  }
  
  @ViewBuilder
  func ToastView(_ id: String, _ text: String, _ icon: String) -> some View {
      HStack {
        Image(systemName: icon)
        Text(text).font(.system(size: 13.0, weight: .regular, design: .default))
        Spacer()
      }
      .padding()
      .background(
          RoundedRectangle(cornerRadius: 24)
              .fill(.orange)
              .shadow(color: .black.opacity(0.06), radius: 3, x: -1, y: -3)
              .shadow(color: .black.opacity(0.06), radius: 2, x: 1, y: 3)
      )
      .padding(.horizontal)
  }
}

struct FilterButtonView: View {
  @EnvironmentObject private var areasViewModel: AreasViewModel
  @EnvironmentObject private var placesViewModel: PlacesViewModel
  @Environment(\.colorScheme) var colorScheme
  let title: String
  let imageName: String
  let type: PlaceFilter
  var onButtonTap: () -> Void
  
  var body: some View {
    Button(action: {
      areasViewModel.firstScreenVisible = false
      areasViewModel.loadingTour = false
      areasViewModel.selectedTour = SchemaV1.Tour()
      areasViewModel.selectedArea = SchemaV1.Area()
      areasViewModel.iconAltitudeMaximum = 50000
      areasViewModel.placeFilter = type
      areasViewModel.visible = false
      areasViewModel.iconResizePercent = 0.0
      areasViewModel.distance = 0.0
      areasViewModel.selectedTour.tourId = -1
      let span = MKCoordinateSpan(latitudeDelta: areasViewModel.zoom, longitudeDelta: areasViewModel.zoom)
      let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.24059, longitude: -70.90502), span: span)
      areasViewModel.mapCameraPosition = MapCameraPosition.region(region)
      
//      } else if title == "Update Yelp" {
//        let dataService = DataService()
//        let places = placesViewModel.places.filter { $0.areaId == 5 }
//        var counter = 0
//        places.forEach { place in
//          if place.yelpCategory == "" && counter < 11 {
//            dataService.updateYelp(name: place.name)
//            counter += 1
//          }
//        }
//      } else if title == "Update Google" {
//        let dataService = DataService()
//        let places = placesViewModel.places.filter { $0.areaId == 5 }
//        places.forEach { place in
//          dataService.updateGoogle(name: place.name)
//        }
      
      areasViewModel.updateRegion(areasViewModel.mapCameraPosition)

      Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
        withAnimation(.easeInOut) {
          areasViewModel.showCardView = false
          areasViewModel.visible = false
          areasViewModel.firstScreenVisible = false
          onButtonTap()
        }
      }
    }) {
      HStack {
        if type == .BucketList {
          Image(imageName)
        } else {
          Image(systemName: imageName)
        }
        
        Text(title)
      }
      .padding(6)
    }
    .foregroundColor(colorScheme == .dark ? .white : .black)
    .background(areasViewModel.placeFilter == type ? Color("AccentTabColor") : colorScheme == .dark ? .black : .white)
    .font(.system(size: 10))
    .fontWeight(.semibold)
    .cornerRadius(10.0)
    .shadow(color: .black.opacity(0.75), radius: 2, x: 1, y: 1)
  }
}
  
extension MainView {
  private var areaMapLayer: some View {
    Map(initialPosition: position) {
      ForEach(areasViewModel.areas) { area in
        Annotation(area.name, coordinate: area.coordinates) {
          AreaAnnotationView(area: area, selected: areasViewModel.selectedArea == area, opacity: annotationOpacity)
            .scaleEffect(areasViewModel.selectedArea == area ? 1.2 : 0.7)
            .shadow(radius: 10)
            .onTapGesture {
              let previewWasVisible = areasViewModel.showCardView
              areasViewModel.scrollItemId = 0

              if ((area.areaId == areasViewModel.selectedArea.areaId && previewWasVisible == true) || (skipAreaCard == true && area.areaId != 11 && area.areaId != 12 && area.name != "More-Brewer Park")) {
                withAnimation(.easeInOut) {
                  if skipAreaCard == true {
                    areasViewModel.selectedArea = area
                  }
                  areasViewModel.distance = 0.0
                  let span = MKCoordinateSpan(latitudeDelta: areasViewModel.zoom, longitudeDelta: areasViewModel.zoom)
                  areasViewModel.mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: area.centerCoordinates, span: span))
                  areasViewModel.visible = false
                }
                Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                  withAnimation(.easeInOut) {
                    areasViewModel.showCardView = false
                  }
                }
              } else {
                Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                  withAnimation(.easeInOut) {
                    areasViewModel.imagePath = placesViewModel.visible == true ? "\(areasViewModel.selectedArea.shortName)/\(placesViewModel.selectedPlace.name)" : "\(areasViewModel.selectedArea.shortName)/Area"
                    areasViewModel.imageCount = placesViewModel.visible == true ? placesViewModel.selectedPlace.imageCount : areasViewModel.selectedArea.imageCount == 0 ? 1 : areasViewModel.selectedArea.imageCount
                    areasViewModel.areaImageUrl = "\(area.shortName)/Area/0"
                  }
                }
                areasViewModel.selectedArea = area
                placesViewModel.selectedPlace = SchemaV1.Place()
              }
              withAnimation(.easeInOut) {
                if skipAreaCard == false || areasViewModel.isBucketPointList(area: area) == true {
                  areasViewModel.showCardView = true
                  areasViewModel.iconResizePercent = 0.0
                  areasViewModel.areaImageUrl = ""
                }
                areasViewModel.firstScreenVisible = false
              }
            }
        }
        .annotationTitles(.hidden)
      }
      MapPolygon(coordinates: hinghamCoordinates)
        .stroke(.accent, lineWidth: 2)
        .foregroundStyle(.accent.opacity(0.1))
    }
    .onChange(of: imagery3DMode) { oldValue, newValue in
      mapStyle = newValue == true ? areasViewModel.satelliteMapStyle : areasViewModel.standardMapStyle
      areasViewModel.imagery3DMode = newValue
    }
    .ignoresSafeArea()
    .mapStyle(mapStyle)
    .onMapCameraChange(frequency: .continuous, {
      annotationOpacity = 0.3
    })
    .onMapCameraChange(frequency: .onEnd) { context in
      annotationOpacity = 1.0
    }
  }
  
  private var placeMapLayer: some View {
    @AppStorage("BucketList") var bucketList: String = ""
    let bucketListArray = bucketList.components(separatedBy: ",")
    let area:SchemaV1.Area = areasViewModel.selectedArea
    var places: [SchemaV1.Place] = placesViewModel.places
    
    if areasViewModel.selectedTour.tourId == -1 {
      if areasViewModel.placeFilter != .None {
        if areasViewModel.placeFilter == .Shopping {
          let includedTypes: [Int] = [2, 3, 5, 9]
          places = places.filter { item in
            includedTypes.contains(item.type)
          }
        } else if areasViewModel.placeFilter == .BucketList {
          places = places.filter { bucketListArray.contains($0.documentID) }
        } else {
          places = places.filter { $0.type == areasViewModel.placeFilter.rawValue }
        }
      }
    }
    
    let currentAltitudeFeet: Double = areasViewModel.mapCameraPosition.region!.span.latitudeDelta * 364000
    let maximumAltitudeFeet: Double = areasViewModel.selectedTour.tourId == -1 ? Double(areasViewModel.iconAltitudeMaximum) : 1000000.0
    let latDeltaHalf: Double = areasViewModel.mapCameraPosition.region!.span.latitudeDelta / 1.5
    let lngDeltaHalf: Double = areasViewModel.mapCameraPosition.region!.span.longitudeDelta / 1.5
    let lat: Double = areasViewModel.mapCameraPosition.region!.center.latitude
    let lng: Double = areasViewModel.mapCameraPosition.region!.center.longitude
    
    if areasViewModel.selectedTour.tourId == -1 {
      places = places.filter { $0.locationLat > lat - latDeltaHalf && $0.locationLat < lat + latDeltaHalf && $0.locationLat > lng - lngDeltaHalf && $0.locationLng < lng + lngDeltaHalf }
    } else {
      places = []
      let tourPlaces = placesViewModel.tourPlaces.filter { $0.tourId == areasViewModel.selectedTour.tourId}
      tourPlaces.forEach { tourPlace in
        let place = placesViewModel.places.first(where: { place in
          place.documentID == tourPlace.placeDocId
        })
        
        if place != nil {
          if tourPlace.name != "" {
            place!.name = tourPlace.name
            place!.shortName = tourPlace.name
            place!.nickname = tourPlace.name
          }
          if tourPlace.notes != "" {
            place!.notes = tourPlace.notes
          }
          places.append(place!)
        } else {
          print(tourPlace.placeDocId)
        }
      }
    }
    
    return ZStack {
      MapReader { proxy in
        Map(position: $areasViewModel.mapCameraPosition, bounds: MapCameraBounds(minimumDistance: 0), interactionModes: interactionModes, scope: nil) {
          if currentAltitudeFeet < maximumAltitudeFeet {
            ForEach(places) { place in
              if showHouses == true || (showHouses == false && place.type != 6) {
                Annotation("", coordinate: place.coordinates) {
                  PlaceAnnotationView(areaName: place.areaName, placeName: place.name, shortName: place.shortName, specials: place.specials, type: place.type, iconSize: place.iconSize, selected: place.selected, opacity: annotationOpacity, iconResizePercent: areasViewModel.iconResizePercent, placeFilter: areasViewModel.placeFilter, imagery3DMode: imagery3DMode, showLabels: showLabels)
                    .shadow(radius: 10)
                    .onTapGesture {
                      areasViewModel.loadingPlaces = false
                      if place.type < 20 {
                        areasViewModel.updateAddToBucketlist(place.documentID)
                        areasViewModel.areaImageUrl = ""
                        if place.videoUrl != "" {
                          Task {
                            withAnimation(.easeInOut) {
                              placesViewModel.setPlaceSelected(area, place)
                              areasViewModel.visible = false
                              areasViewModel.showCardView = true
                              areasViewModel.areaImageUrl = "\(place.areaName)/\(place.name)/0"
                            }
                          }
                        } else {
                          withAnimation(.easeInOut) {
                            placesViewModel.setPlaceSelected(area, place)
                            areasViewModel.visible = false
                            areasViewModel.showCardView = true
                            if place.name == "Iron Horse Statue" {
                              areasViewModel.scrollItemId = 0
                              areasViewModel.areaImageUrl = "\(place.areaName)/\(place.name)/0"
                            }
                          }
                        }
                      }
                    }
                }
                .annotationTitles(.visible)
              }
            }
          }
          
          UserAnnotation()
        }
        .ignoresSafeArea()
        .onChange(of: imagery3DMode) { oldValue, newValue in
          mapStyle = newValue == true ? areasViewModel.satelliteMapStyle : areasViewModel.standardMapStyle
        }
        .onMapCameraChange(frequency: .onEnd) { context in
          cameraIsChanging = false
        }
        .onMapCameraChange(frequency: .continuous) { context in
          @AppStorage("IconAltitudeMaximum") var iconAltitude = 6000
          areasViewModel.iconAltitudeMaximum = areasViewModel.iconAltitudeMaximum != 50000 ? iconAltitude : areasViewModel.iconAltitudeMaximum
          let distanceDelta = areasViewModel.distance - context.camera.distance
          cameraIsChanging = true
          
          if areasViewModel.distance == 0.0 {
            areasViewModel.distance = context.camera.distance
          } else if areasViewModel.distance != context.camera.distance && abs(distanceDelta) > 20 {
            let saveAreaId:Int = areasViewModel.selectedArea.areaId
            areasViewModel.selectedArea.areaId = -1
            
            if (UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight) && UIDevice.current.userInterfaceIdiom == .phone {
              areasViewModel.iconResizePercent = areasViewModel.distance / (context.camera.distance * 2.43)
            } else {
              areasViewModel.iconResizePercent = areasViewModel.distance / context.camera.distance
            }
            
//            if areasViewModel.placeFilter != .None {
//              areasViewModel.iconResizePercent *= 0.075
//            }
            areasViewModel.selectedArea.areaId = saveAreaId
          }
          
          areasViewModel.centerCoordinate = context.region.center
          
          if areasViewModel.mapCameraPosition.region == nil {
            areasViewModel.mapCameraPosition = MapCameraPosition.region(context.region)
          }
          
          if areasViewModel.selectedArea.areaId == -1 {
            let span = MKCoordinateSpan(latitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.05, longitudeDelta: UIDevice.current.userInterfaceIdiom == .pad ? 0.145 : 0.05)
            areasViewModel.mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.22527,longitude: -70.88028), span: span))
            areasViewModel.loadingTour = false
          }
        }
        .background(.white)
        .mapStyle(mapStyle)
        .mapControls {
          Button {
            let span = MKCoordinateSpan(latitudeDelta: areasViewModel.zoom, longitudeDelta: areasViewModel.zoom)
            areasViewModel.mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.userLocation?.coordinate.latitude ?? 0.0, longitude: location.userLocation?.coordinate.longitude ?? 0.0), span: span))
          } label: {
            Image(systemName: "location.fill")
          }
        }
        .simultaneousGesture (
          DragGesture(minimumDistance: 0.0)
            .onChanged { value in
              let location = value.startLocation
              if let pinLocation = proxy.convert(location, from: .local) {
                longPressCoordinate = pinLocation
              }
            }
            .simultaneously(with: LongPressGesture(minimumDuration: 0.5)
              .onEnded { _ in
                if let coordinate = longPressCoordinate {
                  let request = MKLookAroundSceneRequest(coordinate: coordinate)
                  request.getSceneWithCompletionHandler { scene, error in
                    if let error = error {
                      print("Error fetching Look Around scene: \(error.localizedDescription)")
                      return
                    }
                    if let scene {
                      lookAroundScene = scene
                      isShowingLookAroundViewer = true
                    }
                  }
                }
              }
            )
          )
        }
      }
  }
  
  private var ellipsisMenu: some View {
    Menu {
      Menu {
        ForEach(areasViewModel.tours, id: \.self) { tour in
          Button {
            withAnimation(.easeInOut) {
              areasViewModel.firstScreenVisible = false
              areasViewModel.loadingTour = true
              areasViewModel.selectedArea = SchemaV1.Area()
              areasViewModel.selectedArea = SchemaV1.Area()
              areasViewModel.selectedTour = tour
              areasViewModel.iconResizePercent = 0.0
              areasViewModel.visible = false
              areasViewModel.placeFilter = .None
              let span = MKCoordinateSpan(latitudeDelta: areasViewModel.zoom, longitudeDelta: areasViewModel.zoom)
              let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 42.24059, longitude: -70.90502), span: span)
              areasViewModel.mapCameraPosition = MapCameraPosition.region(region)
            }
          }
          label: {
            Text(tour.name)
          }
        }
      } label: {
        Label("Tours", systemImage: "signpost.right.and.left")
      }
      
      Menu {
        ForEach(areasViewModel.videos, id: \.self) { video in
          Button {
            let urlString:String = "https://youtu.be/\(video.youtubeId)"
            guard let url:URL = URL(string: urlString) else { return }
              
            openUrl(url) { accepted in
                if !accepted {
                  _ = Alert(title: Text("Videos"), message: Text("\(video.youtubeId) video could not be opened."), dismissButton: .default(Text("OK")))
                }
            }
          }
          label: {
            Text(video.name)
          }
        }
      } label: {
        Label("Videos", systemImage: "video")
      }
      
      Toggle(isOn: $imagery3DMode) {
        Label("3D Satellite", systemImage: "square.3.layers.3d")
      }
      .disabled(areasViewModel.visible == true)
      
      Toggle(isOn: $showHouses) {
        Label("Show Houses", systemImage: "house")
      }
      .disabled(areasViewModel.visible == true)
      
      Toggle(isOn: $showSpecials) {
        Label("Show Specials", systemImage: "tag")
      }
      .disabled(areasViewModel.visible == true)
      .onChange(of: showSpecials) { oldValue, newValue in
        @AppStorage("ShowSpecials") var showSpecial: Bool = true
        showSpecial = newValue
        areasViewModel.selectedArea = areasViewModel.selectedArea
      }
      
      Toggle(isOn: $showLabels) {
        Label("Show Labels", systemImage: "textformat.characters")
      }
      .disabled(areasViewModel.visible == true)
      
      Button {
        let urlString:String = "mailto:support@cambuilt.com?subject=Here's%20Hingham!"
        guard let url:URL = URL(string: urlString) else { return }
          
        openUrl(url) { accepted in
            if !accepted {
                // Handle the error, e.g., show an alert
            }
        }
      }
      label: {
        Label("Contact Us", systemImage: "envelope")
      }
        
    } label: {
      Image(systemName: "ellipsis")
    }
  }
  
  private var filterHScrollToolbar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHStack(spacing: 10) {
        FilterButtonView(title: "Bucket List", imageName: "bucket", type: .BucketList) { mapStyle = areasViewModel.standardMapStyle }
        FilterButtonView(title: "Dining", imageName: "fork.knife", type: .Dining) {}
        FilterButtonView(title: "Coffee", imageName: "cup.and.saucer", type: .Coffee) {}
        FilterButtonView(title: "Shopping", imageName: "handbag", type: .Shopping) {}
        FilterButtonView(title: "Parks", imageName: "tree", type: .Park) {}
        
//        FilterButtonView(title: "Events", imageName: "calendar", type: .None) {
//          
//        }
//        FilterButtonView(title: "Videos", imageName: "video", type: .None) {
//          
//        }
//                FilterButtonView(title: "Update Yelp", imageName: "gear", type: 100)
//                FilterButtonView(title: "Update Google", imageName: "gear", type: 100)
      }
      .padding(.horizontal)
      .padding([.leading, .trailing], 10)
    }
    .frame(height:50)
    .background(.clear)
  }
  
  private var bucketPointImageSection: some View {
    HStack(alignment: .center) {
      if (areasViewModel.selectedArea.videoUrl != "" || placesViewModel.selectedPlace.videoUrl != "") && areasViewModel.scrollItemId == 0 {
        if areasViewModel.visible == true {
          if UIDevice.current.userInterfaceIdiom == .phone {
            YouTubeView(videoID: areasViewModel.selectedArea.videoUrl)
              .frame(width: UIScreen.main.bounds.size.width * 0.93)
              .cornerRadius(25)
          } else {
            YouTubeView(videoID: areasViewModel.selectedArea.videoUrl)
              .frame(width: UIScreen.main.bounds.size.width * 0.3)
              .cornerRadius(25)
          }
        } else {
          if UIDevice.current.userInterfaceIdiom == .phone {
            YouTubeView(videoID: placesViewModel.selectedPlace.videoUrl)
              .frame(width: UIScreen.main.bounds.size.width * 0.93)
              .cornerRadius(25)
          } else {
            YouTubeView(videoID: placesViewModel.selectedPlace.videoUrl)
              .frame(width: UIScreen.main.bounds.size.width * 0.3)
              .cornerRadius(25)
          }
        }
      } else if areasViewModel.areaImageUrl == "Lincoln/No Noise Hingham/5" {
        YouTubeView(videoID: "Dk9TqHEPPX8")
      } else if areasViewModel.areaImageUrl != "" {
        Image(areasViewModel.areaImageUrl)
          .resizable()
          .scaledToFit()
          .cornerRadius(25)
      }
    }
    .padding(0)
    .padding(.top, 40)
    .padding(.bottom, -110)
    .frame(width: UIScreen.main.bounds.size.width * (areasViewModel.firstScrollItemType(place: placesViewModel.selectedPlace) == "firstBucket•Video" ? 0.9 : 0.9), height: UIScreen.main.bounds.size.height * (areasViewModel.firstScrollItemType(place: placesViewModel.selectedPlace) == "firstBucket•Video" ? 0.248 : 0.248))
    .overlay(
        RoundedRectangle(cornerRadius: 25)
          .stroke(Color.accent, lineWidth: 6)
          .padding(.top, 40)
          .padding(.bottom, -110)
          .frame(width: UIScreen.main.bounds.size.width * (areasViewModel.firstScrollItemType(place: placesViewModel.selectedPlace) == "firstBucket•Video" ? UIDevice.current.userInterfaceIdiom == .phone ? 0.92 : 0.3 : 0.9), height: UIScreen.main.bounds.size.height * (areasViewModel.firstScrollItemType(place: placesViewModel.selectedPlace) == "firstBucket•Video" ? 0.248 : 0.248))
    )
    .overlay(alignment: .topTrailing) {
      Button {
        withAnimation(.easeInOut) {
          areasViewModel.showCardView = false
          if areasViewModel.visible == true {
            areasViewModel.selectedArea = areasViewModel.areas[0]
          }
        }
      }
      label: {
         Image(systemName: "xmark.circle.fill")
          .font(.system(size: 24))
      }
      .foregroundColor(.white)
      .padding()
      .padding(.top, 40)
    }
  }
}

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
  private let manager = CLLocationManager()
  @Published var userLocation: CLLocation?
  @Published var message: String = ""
  @Published var showMessage = false
  @Published var newPlaceAtCurrentLocation: SchemaV1.Place?
  @Published var placesViewModel: PlacesViewModel = PlacesViewModel()
  @Published var areaId = 0
  
  func startUpdating() {
    manager.delegate = self
    manager.requestWhenInUseAuthorization()
    manager.startUpdatingLocation()
  }
  
  func stopUpdating() {
    manager.stopUpdatingLocation()
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if let clError = error as? CLError {
        switch clError.code {
        case .denied:
            print("Location access was denied by the user.")
        case .locationUnknown:
            print("Location is currently unknown, but the manager will keep trying.")
        case .network:
            print("Network error prevented location retrieval.")
        default:
            print("A Core Location error occurred: \(clError.localizedDescription)")
        }
    } else {
        print("General error: \(error.localizedDescription)")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    userLocation = locations.last
    
    let placesFound = placesViewModel.places.filter {   // $0.areaId == areaId &&
      return userLocation!.coordinate.latitude > $0.locationLat - 0.0005 &&
      userLocation!.coordinate.latitude < $0.locationLat + 0.0005 &&
      userLocation!.coordinate.longitude > $0.locationLng - 0.0005 &&
      userLocation!.coordinate.longitude < $0.locationLng + 0.0005
    }
    
    let placeCount = placesFound.count
    
    if placeCount > 0 {
      var closestPlace = placesFound[0]
      placesFound.forEach { place in
        if closestPlace.name != place.name {
          if abs(userLocation!.coordinate.latitude - place.locationLat) <= abs(userLocation!.coordinate.latitude - closestPlace.locationLat) &&
              abs(userLocation!.coordinate.longitude - place.locationLng) <= abs(userLocation!.coordinate.longitude - closestPlace.locationLng)
          {
            closestPlace = place
          }
        }
      }
      
      newPlaceAtCurrentLocation = closestPlace
      print("updated locations")
    }
  }
}

class IconImage: ObservableObject {
  @Published var name: String
  
  init(_name: String) {
    name = _name
  }
}

struct YouTubeView: UIViewRepresentable {
  @EnvironmentObject private var areasViewModel: AreasViewModel
  let videoID: String

  func makeUIView(context: Context) -> YTPlayerView {
    let playerVars: [AnyHashable: Any] = ["autoplay": 1, "controls": 0, "origin": "https://www.youtube.com", "playsinline": 1]
    areasViewModel.ytPlayerView.load(withVideoId: videoID, playerVars: playerVars)
    return areasViewModel.ytPlayerView
  }

  func updateUIView(_ uiView: YTPlayerView, context: Context) {
    // Update the player if the video ID changes
  }
}

enum PlaceFilter: Int {
  case None = 0
  case Dining = 1
  case Shopping = 2
  case Clothing = 3
  case Gym = 4
  case Pharmacy = 5
  case Historic = 6
  case Coffee = 7
  case Park = 8
  case Salon = 9
  case BucketList = 11
}

extension Date {
    func dayNumberOfWeek() -> Int {
        return Calendar.current.dateComponents([.weekday], from: self).weekday! - 1
    }
}

