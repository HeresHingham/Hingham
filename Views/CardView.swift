//
//  AreaPreviewView.swift
//  Here's Hingham!
//
//  Created by Cameron Conway on 4/30/25.
//

import SwiftUI
import MapKit
import AVKit

struct CardView: View {
  @EnvironmentObject private var areasViewModel: AreasViewModel
  @EnvironmentObject private var placesViewModel: PlacesViewModel
  @Environment(\.colorScheme) var colorScheme
  @ObservedObject var location: LocationManager = LocationManager()
  @Binding var showPlaceDetail: Bool
  @Binding var mapStyle: MapStyle
  @Binding var imagery3DMode: Bool
  @State private var scrollViewID = UUID()
  @State private var scrolledID = CGFloat.zero
  @State var showHours = false
  @State var showRatingSelector = false
  @State private var tabSelection: Int = 0

  let area: SchemaV1.Area
  
  var body: some View {
    VStack {
      HStack(alignment: .top) {
        if ((area.shortName == "World's End" || area.shortName == "More-Brewer") && areasViewModel.visible == true) || placesViewModel.selectedPlace.name == "Iron Horse Statue" || placesViewModel.selectedPlace.name == "No Noise Hingham" {
        } else {
          VStack(alignment: .leading) {
            imageSection
          }
        }
      }

      titleSection
      
      if areasViewModel.visible == false && placesViewModel.selectedPlace.type != 12 && placesViewModel.selectedPlace.type != 13 && !placesViewModel.isBucketPointList(place: placesViewModel.selectedPlace) && (placesViewModel.selectedPlace.googleRating > 0 || placesViewModel.selectedPlace.yelpRating > 0 || placesViewModel.selectedPlace.type < 7)
      {
        HStack {
          if placesViewModel.selectedPlace.type == 6 {
            historicHouseSection
              .padding(.top, -16)
              .padding(.bottom, 10)
          } else {
            reviewsSection
              .padding(.top, -20)
              .padding(.bottom, 10)
          }
        }
      }
      HStack {
        VStack(alignment: .leading)
        {
          notesSection
        }
      }
      .padding(.top, areasViewModel.visible == true || [8,12,13,15].contains(where: { type in
        type == placesViewModel.selectedPlace.type}) ? -40 : -10)
      
      HStack
      {
        if areasViewModel.visible == true {
          enterButton
        }
        directionsButton
        if areasViewModel.visible == false {
          addToBucketListButton
        }
      }
      .padding(.top, 10)
      .padding(.bottom, 25)
      .padding([.leading, .trailing], 25)
    }
    .background(
      Rectangle()
        .fill(colorScheme == .dark ? .black : .white)
    )
    .clipShape(RoundedRectangle(cornerRadius: 35))
    .padding(5)
    .background(.accent.opacity(0.5))
    .cornerRadius(35)
    .shadow(color: .black.opacity(0.75), radius: 3, x: 2, y: 2)
    .overlay {
      if showHours == true {
        if placesViewModel.selectedPlace.hours.lengthOfBytes(using: String.Encoding.utf8) > 30 {
          hoursWindow
        }
      }
    }
    .onTapGesture(perform: {
      withAnimation {
        areasViewModel.showCardView = false
        if areasViewModel.visible == true {
          onEnterButtonTapped()          
        }
      }
    })
  }
}

extension CardView {
  private var imageSection: some View {
    ZStack {
      TabView(selection:$tabSelection) {
        if areasViewModel.visible == true {
          ForEach(0..<areasViewModel.imageCount, id: \.self) { index in
            GeometryReader { geometry in
              if areasViewModel.selectedArea.videoUrl != "" {
                YouTubeView(videoID: areasViewModel.selectedArea.videoUrl)
                  .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.4)
                  .cornerRadius(25)
                  .overlay(
                    RoundedRectangle(cornerRadius: 25)
                      .stroke(Color.accent.opacity(0.5), lineWidth: 6)
                      .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.4)
                  )
                  .tag(0)
              } else {
                if UIImage(named: "\(areasViewModel.imagePath)/\(index)") != nil {
                  Image("\(areasViewModel.imagePath)/\(index)")
                    .resizable()
                    .scaledToFill()
                    .tag(index)
                }
              }
            }
          }
        } else {
          ForEach(0..<placesViewModel.selectedPlace.imageCount, id: \.self) { index in
            let indexSegment = "/" + String(index)
            if UIImage(named: areasViewModel.getImageUrl(placeName: placesViewModel.selectedPlace.name.replacingOccurrences(of: "/", with: "")).replacingOccurrences(of: "/0", with: indexSegment)) != nil {
              Image(areasViewModel.getImageUrl(placeName: placesViewModel.selectedPlace.name.replacingOccurrences(of: "/", with: "")).replacingOccurrences(of: "/0", with: indexSegment))
                .resizable()
                .scaledToFill()
                .tag(index)
            }
          }
        }
        
        if placesViewModel.visible == true && areasViewModel.imageCount < 10 {
          ForEach(10..<15, id: \.self) { index in
            if UIImage(named: "\(areasViewModel.imagePath)/\(index)") != nil {
              ZStack(alignment: .bottomLeading) {
                Image("\(areasViewModel.imagePath)/\(index)")
                  .resizable()
                  .scaledToFill()
              }
            }
          }
        }
      }
      .tabViewStyle(PageTabViewStyle())
      .onChange(of: tabSelection) { oldValue, newValue in
        if newValue > 0 {
          areasViewModel.ytPlayerView.stopVideo()
        }
      }
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
      }
    }
  }
  
  private var enterButton: some View {
    let design = placesViewModel.selectedPlace.type == 6 ? Font.Design.serif : Font.Design.default
    let weight = placesViewModel.selectedPlace.type == 6 ? Font.Weight.semibold : Font.Weight.bold

    return Button {
      onEnterButtonTapped()
    } label: {
      Text("Enter")
        .font(.system(.headline, design: design, weight: weight))
        .frame(width: 125, height: 25)
    }
    .buttonStyle(.borderedProminent)
    .disabled(areasViewModel.loadingPlaces)
  }
  
  private func onEnterButtonTapped() {
    if areasViewModel.loadingPlaces == false {
      areasViewModel.loadingPlaces = true
    } else {
      return
    }
    
    if areasViewModel.visible == false {
      if areasViewModel.selectedArea != area {
        areasViewModel.selectedArea = area
      }
      placesViewModel.setPlaceSelected(area, placesViewModel.selectedPlace)
      areasViewModel.visible = placesViewModel.selectedPlace.name == ""
      withAnimation(.easeInOut) {
        showPlaceDetail = !showPlaceDetail
      }
    } else {
      withAnimation(.easeInOut) {
        if area.name == "World's End" || area.name == "More-Brewer Park" || area.name == "Turkey Hill" {
          mapStyle = areasViewModel.satelliteMapStyle
          imagery3DMode = false
        }
        if (area.areaId == areasViewModel.selectedArea.areaId) {
          areasViewModel.distance = 0.0
          let span = MKCoordinateSpan(latitudeDelta: areasViewModel.zoom, longitudeDelta: areasViewModel.zoom)
          areasViewModel.mapCameraPosition = MapCameraPosition.region(MKCoordinateRegion(center: area.centerCoordinates, span: span))
        } else {
          areasViewModel.selectedArea = area
          placesViewModel.selectedPlace = SchemaV1.Place()
        }
      }
      
      areasViewModel.firstScreenVisible = false
      
      Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
        withAnimation(.easeInOut) {
          areasViewModel.showCardView = false
          if (area.areaId == areasViewModel.selectedArea.areaId) {
            areasViewModel.visible = false
          }
        }
      }
    }
  }
  
  private var directionsButton: some View {
    let design = Font.Design.default
    let weight = placesViewModel.selectedPlace.type == 6 ? Font.Weight.semibold : Font.Weight.bold

    return HStack {
      Button {
        location.startUpdating()
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
          if let userLocation = location.userLocation {
            var targetLat = area.centerCoordinateLat
            var targetLng = area.centerCoordinateLng
            
            if placesViewModel.selectedPlace.name != "" {
              targetLat = placesViewModel.selectedPlace.locationLat
              targetLng = placesViewModel.selectedPlace.locationLng
            }
            
            let urlString = "http://maps.apple.com/?saddr=\(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude)&daddr=\(targetLat),\(targetLng)"
            
            if let url = URL(string: urlString) {
              if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
              }
            }
          }
        }
      } label: {
        Text("Directions")
          .font(.system(size: 18, weight: weight, design: design))
          .frame(width: 125, height: 25)
      }
      .buttonStyle(.bordered)
      .disabled(areasViewModel.loadingPlaces)
    }
  }
  
  private var addToBucketListButton: some View {
    let design = Font.Design.default
    let weight = Font.Weight.bold
    let documentID = placesViewModel.selectedPlace.documentID
    
    return Button {
      withAnimation(.easeInOut) {
        @AppStorage("BucketList") var bucketList: String = ""
        var bucketListArray = bucketList.components(separatedBy: ",")
        
        if areasViewModel.showAddToBucketList == true {
          bucketListArray.append(documentID)
          areasViewModel.showAddToBucketList = false
          bucketList = bucketListArray.joined(separator: ",")
        } else {
          if bucketListArray.count > 0 {
            let documentID = placesViewModel.selectedPlace.documentID
            if bucketListArray.contains(documentID) {
              bucketListArray.remove(at: bucketListArray.firstIndex(of: documentID)!)
              areasViewModel.showAddToBucketList = true
              bucketList = bucketListArray.joined(separator: ",")
            }
          }
        }
      }
      @AppStorage("BucketList") var bucketList: String = ""
    } label: {
      Text(areasViewModel.showAddToBucketList == true ? "+ Bucket List" : "- Bucket List")
        .font(.system(size: 16, weight: weight, design: design))
          .frame(width: 115, height: 25)
    }
    .buttonStyle(.bordered)
  }
  
  private var notesSection: some View {
    let place = placesViewModel.selectedPlace
    let design = place.type == 6 ? Font.Design.serif : Font.Design.default
    @AppStorage("ShowSpecial") var showSpecial: Bool = true
    let placeNotes = imageNameIfSpecialIsToday(special: place.specials, showSpecial: showSpecial) == "" ? place.notes : place.specialNotes
    let descText = (areasViewModel.visible == true || place.name == "" ? area.desc : placeNotes) + "\r\n\r\n\r\n\r\n"
    let descLocalizedStringKey: LocalizedStringKey = LocalizedStringKey(stringLiteral: descText)
    let path = placesViewModel.visible == true ? "\(area.shortName)/\(placesViewModel.selectedPlace.name)" : "\(area.shortName)/Area"

    return VStack {
      Divider()
        .padding(.top, areasViewModel.visible == true ? 10 : 15)
      FadingScrollView(place: place, area: area, design: design, descText: descText, path: path, descLocalizedStringKey: descLocalizedStringKey, areasViewModel: areasViewModel, placesViewModel: placesViewModel)
        .padding([.leading, .trailing], 15)
        .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 100 : 180)
    }
  }
  
  private var titleSection: some View {
    let place = placesViewModel.selectedPlace
    let design = placesViewModel.selectedPlace.type == 6 ? Font.Design.serif : Font.Design.default
    let standardFont = Font.system(size: 19.0, weight: .bold, design: design)
    let smallTextFont = placesViewModel.selectedPlace.type == 6 ? Font.system(size: 12.0, weight: .regular, design: .serif) : Font.system(size: 12.0, weight: .regular, design: .default)
    var url: URL? = nil
    var name = ""
    
    if placesViewModel.selectedPlace.name != "" {
      let place = placesViewModel.selectedPlace
      if place.website != "" {
        url = URL(string: place.website)!
      }
    }

    name = areasViewModel.visible == true || place.name == "" ? area.name : place.name
    name += name.hasSuffix("Historic") ? " District" : ""
    let address = areasViewModel.visible == true || place.name == "" ? "" : place.address
    
    return VStack {
      HStack {
        VStack(alignment: .leading) {
          if url == nil {
            Text(name)
              .font(standardFont)
              .foregroundColor(.primary)
              .fontDesign(design)
              .scaledToFill()
              .minimumScaleFactor(0.5)
              .lineLimit(1)
              .onChange(of: placesViewModel.selectedPlace) {
                scrollViewID = UUID()
              }
          } else {
            Link(name, destination: url!)
              .font(standardFont)
              .lineLimit(1)
              .minimumScaleFactor(0.5)
              .foregroundColor(.red)
          }
          if (place.type != 6) {
            Text(place.desc == "" ? place.yelpCategory : place.desc)
              .font(smallTextFont)
              .padding(.leading, 2)
          }
        }
        Spacer()
        Text(address)
          .font(.system(.footnote, design: design, weight: .regular))
      }
      .padding(20)
      .padding(.top, areasViewModel.visible == true ? -10 : -20)
    }
  }
  
  private var hoursWindow: some View {
    let hours = placesViewModel.selectedPlace.hours.components(separatedBy: ";")
    let cols = [GridItem(.fixed(100)), GridItem(.fixed(120))]
    
    return ZStack {
      VStack(alignment: .center) {
        Text("Hours")
          .fontWeight(.bold)
          .padding(.top, -3)
        
        ForEach(0..<7, id: \.self) { index in
          LazyVGrid(columns: cols, alignment: .leading) {
            let weekDay = String(describing: WeekDays.allCases[index])
            Text(weekDay)
              .font(.system(size: 13))
              .foregroundColor(.primary)
            Text(hours[index].components(separatedBy: ",")[1])
              .font(.system(size: 13))
              .foregroundColor(.primary)
          }
          .padding([.top, .bottom], -3)
        }
      }
      .padding()
      Image(systemName: "xmark")
        .font(.system(size: 16))
        .padding(.leading, 220)
        .padding(.bottom, 130)
    }
    .background(.white)
    .frame(width: 280)
    .cornerRadius(25)
    .onTapGesture {
      showHours = false
    }
    .shadow(color: .black.opacity(0.75), radius: 4, x: 3, y: 3)
  }

  enum WeekDays: CaseIterable {
    case Sunday
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday
  }
  
  private func getHoursOpen(hours: String) -> String {
    if !hours.contains(";") {
      return hours
    }

    let daysHours = hours.components(separatedBy: ";")
        
    for dayHours in daysHours {
      if dayHours != "" {
        let hoursInfo = dayHours.components(separatedBy: ",")
        if hoursInfo[0] == String(Date().dayNumberOfWeek()) || daysHours.count == 2 {
          return hoursInfo[1]
        }
      }
    }
        
    return ""
  }
  
  private var historicHouseSection: some View {
    let place = placesViewModel.selectedPlace
    let labelFont = Font.system(size: 12.0, weight: .semibold, design: .serif)
    let textFont = Font.system(size: 11.5, weight: .regular, design: .serif)
    let columns: [GridItem] = [
      GridItem(.fixed(100.0), spacing: 12),
      GridItem(.fixed(120.0), spacing: 12),
      GridItem(.fixed(100.0), spacing: 12)
    ]
    
    return VStack(alignment: .leading) {
      Divider()

      LazyVGrid(columns: columns, alignment: .leading, spacing: 0) {
        HStack {
          Text("Year Built")
            .font(labelFont)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
          Text(place.yearBuilt == 0 ? "" : "\(place.yearBuilt)".replacingOccurrences(of: ",", with: ""))
            .font(textFont)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
        HStack {
          Text("Style")
            .font(labelFont)
            .lineLimit(1)
          Text(place.archStyle)
            .font(textFont)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.leading, 5)
        }
        HStack {
          Text("Lot")
            .font(labelFont)
            .fontWeight(.semibold)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
          Text("\(place.lotSize == 0 ? "" : String(place.lotSize) + " acre(s)")")
            .font(textFont)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
        .padding(.trailing, 12)
        HStack {
          Text("Square Feet")
            .font(Font.system(size: 10.0, weight: .semibold, design: .serif))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
          Text("\(place.squareFeet == 0 ? "" : place.squareFeet.formatted())")
            .font(textFont)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(.trailing, -7)
        }
        HStack {
          Text("Est Val")
            .font(Font.system(size: 10.0, weight: .semibold, design: .serif))
            .lineLimit(1)
          Text(place.estimatedValue == "unknown" ? "" : place.estimatedValue.isNumber == true ? "$\(place.estimatedValue)" : place.estimatedValue)
            .font(textFont)
            .lineLimit(1)
        }
        HStack {
          if let url = URL(string: placesViewModel.selectedPlace.website) {
            if placesViewModel.selectedPlace.website.contains("zillow") {
              Link(destination: url) {
                Image("Reviews/Zillow")
                  .resizable()
                  .scaledToFill()
                  .frame(width: 56, height: 16)
              }
            } else {
              Link(destination: url) {
                Text("Website")
                  .font(textFont)
                  .padding(.top, 3)
              }
            }
          } else {
            Image("Reviews/Zillow")
              .resizable()
              .scaledToFill()
              .frame(width: 56, height: 16)
          }
        }
        .padding(.trailing, 12)
      }
      .padding(.top, -5)
      .padding(.leading, 18)
    }
    .padding(.top, 0)
    .padding(.bottom, -30)
  }
  
  private var reviewsSection: some View {
    let place = placesViewModel.selectedPlace
    let starPadding = -1.5
    let smallTextFont = place.type == 6 ? Font.system(size: 12.0, weight: .regular, design: .serif) : Font.system(size: 12.0, weight: .regular, design: .default)
    
    let halfStar = Image("Reviews/HalfStar")
      .resizable()
      .scaledToFill()
      .frame(width: 4, height: 8)
      .padding(starPadding)
    let star = Image("Reviews/Star")
      .resizable()
      .scaledToFill()
      .frame(width: 4, height: 8)
      .padding(starPadding)

    return VStack(alignment: .leading) {
      Divider()
        .padding(.top, 2)
        .padding(.bottom, 1)
      
      HStack {
        if placesViewModel.selectedPlace.hours.components(separatedBy: ";").count > 0 {
          Button {
            showHours = true
          } label: {
            Text(getHoursOpen(hours: placesViewModel.selectedPlace.hours))
              .font(smallTextFont)
              .foregroundColor(.red)
              .frame(width: 160, alignment: .leading)
          }
          Spacer()
        } else if placesViewModel.selectedPlace.hours.components(separatedBy: ";").count == 1 {
          Text(placesViewModel.selectedPlace.hours)
            .font(smallTextFont)
            .padding(.leading, 2)
          Spacer()
        }
        Text(place.yelpPrice)
          .font(smallTextFont)
        Spacer()
        if placesViewModel.selectedPlace.menuUrl != "" {
          let menuUrl = URL(string: placesViewModel.selectedPlace.menuUrl)!
          Link(destination: menuUrl) {
            Text("Menu")
              .font(smallTextFont)
              .fontWeight(.bold)
              .foregroundColor(.red)
              .frame(width: 37)
          }
          Spacer()
        } else {
          Spacer()
        }
        Link(destination: URL(string: "tel:" + placesViewModel.selectedPlace.phone)!) {
          Text(placesViewModel.selectedPlace.phone)
            .font(smallTextFont)
        }
      }
      .padding([.leading, .trailing], 18)
      
      let gReviews = placesViewModel.selectedPlace.googleReviews
      let yReviews = placesViewModel.selectedPlace.yelpReviews
      
      if showRatingSelector == false {
        if placesViewModel.selectedPlace.hours != "" || placesViewModel.selectedPlace.yelpPrice != "" || placesViewModel.selectedPlace.phone != "" {
          Divider()
        }
        HStack {
          if placesViewModel.selectedPlace.instagram != "" {
            Link(destination: URL(string: "https://www.instagram.com/\(placesViewModel.selectedPlace.instagram)")!) {
              Image("Reviews/Instagram")
                .resizable()
                .scaledToFill()
                .frame(width: 18, height: 18)
                .padding(.leading, 15)
            }
          } else {
            Spacer()
          }
          
          if gReviews > 0 {
            if let url = URL(string: placesViewModel.selectedPlace.googleUrl) {
              Link(destination: url) {
                Image("Reviews/Google")
                  .resizable()
                  .scaledToFill()
                  .frame(width: 54, height: 18)
              }
            } else if placesViewModel.selectedPlace.googleReviews > 0 {
              Image("Reviews/Google")
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 18)
            }
            
            let gRating = placesViewModel.selectedPlace.googleRating
            
            if gRating > 0 {
              if gRating < 1 { halfStar } else if gRating >= 1 { star }
              if gRating > 1 && gRating < 2 { halfStar } else if gRating >= 2 { star }
              if gRating > 2 && gRating < 3 { halfStar } else if gRating >= 3 { star }
              if gRating > 3 && gRating < 4 { halfStar } else if gRating >= 4 { star }
              if gRating > 4 && gRating < 5 { halfStar } else if gRating >= 5 { star }
            }
            if gReviews > 0 {
              Text("(\(String(gReviews)))")
                .font(.system(size: 10))
                .fontWeight(Font.Weight.light)
                .frame(width: 30)
                .lineLimit(1)
                .padding(.leading, -5)
            }
          }
          
          if yReviews > 0 {
            if let url = URL(string: placesViewModel.selectedPlace.yelpUrl) {
              Link(destination: url) {
                Image("Reviews/Yelp")
                  .resizable()
                  .scaledToFill()
                  .frame(width: 50, height: 16)
              }
            } else if placesViewModel.selectedPlace.yelpReviews > 0 {
              Image("Reviews/Yelp")
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 18)
            }
            
            let yRating = placesViewModel.selectedPlace.yelpRating
            
            if yRating > 0 {
              if yRating < 1 { halfStar } else if yRating >= 1 { star }
              if yRating > 1 && yRating < 2 { halfStar } else if yRating >= 2 { star }
              if yRating > 2 && yRating < 3 { halfStar } else if yRating >= 3 { star }
              if yRating > 3 && yRating < 4 { halfStar } else if yRating >= 4 { star }
              if yRating > 4 && yRating < 5 { halfStar } else if yRating >= 5 { star }
            }
            
            if yReviews > 0 {
              Text("(\(String(yReviews)))")
                .font(.system(size: 10))
                .fontWeight(Font.Weight.light)
                .frame(width: 30)
                .lineLimit(1)
                .padding(.leading, -5)
            }
          }
          
          Button {
            showRatingSelector = true
          } label: {
            Image("Reviews/Bucket\(placesViewModel.selectedPlace.hinghamReviewAverage)Star").resizable().scaledToFit().frame(width: 31, height: 24)
          }
          .padding(.leading, -5)
          
          if (placesViewModel.selectedPlace.hinghamReviews > 0) {
            Text("(\(placesViewModel.selectedPlace.hinghamReviews))")
              .font(.system(size: 10))
              .fontWeight(Font.Weight.light)
              .frame(width: 30)
              .lineLimit(1)
              .padding(.leading, -14)
          }
        }
        .padding(.bottom, 10)
        .padding(.top, -8)
      } else if showRatingSelector == true {
        Divider()
        HStack {
          RatingsView(place: $placesViewModel.selectedPlace, showRatingSelector: $showRatingSelector)
            .padding(.leading, 18)
        }
      }
    }
    .padding(.bottom, -32)
  }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

import SwiftUI

struct FadingScrollView: View {
  @State private var contentOffset: CGPoint = .zero
  var place: SchemaV1.Place
  var area: SchemaV1.Area
  var design: Font.Design
  var descText: String
  var path: String
  var descLocalizedStringKey: LocalizedStringKey
  var areasViewModel: AreasViewModel
  var placesViewModel: PlacesViewModel
  @State public var currentItemID: Int?
  
  var body: some View {
      ScrollView(.vertical, showsIndicators: true) {
        if areasViewModel.visible == true && descText.contains("•") {
          let notes = area.desc
          let bulletLines = notes.filter { $0 != "\n" }.components(separatedBy: "•")
          
          VStack {
            ForEach(Array(bulletLines.enumerated()), id: \.offset) { index, line in
              HStack(alignment: .top) {
                if line != "" && line[line.index(line.startIndex, offsetBy: 1, limitedBy: line.endIndex)!] != " " {
                  Image("bucketpoint")
                    .resizable()
                    .frame(width: 18, height: 14)
                    .padding(0)
                }
                Text(LocalizedStringKey(stringLiteral:line))
                  .font(.system(size: 13.0, weight: .regular, design: design))
                  .id(index)
                Spacer()
              }
            }
          }
          .background(GeometryReader {
            Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
          })
          .scrollTargetLayout()
          .padding(.bottom, 160)
        } else {
          let notes = descText
          let bulletLines = notes.filter { $0 != "\n" } .components(separatedBy: "•")
          
          if descText == "~" {
            ForEach(1..<10, id: \.self) { index in
              if UIImage(named: "\(path)/\(index)") != nil {
                Image("\(path)/\(index)")
                  .resizable()
                  .scaledToFit()
                  .cornerRadius(2)
                  .frame(width: UIScreen.main.bounds.width * 0.91)
                  .padding(0)
              }
            }
          } else if bulletLines.count > 1 {
            VStack {
              ForEach(Array(bulletLines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top) {
                  if let lineIndex = line.index(line.startIndex, offsetBy: 1, limitedBy: line.endIndex) {
                    if line[lineIndex] != " " {
                      Image("bucketpoint")
                        .resizable()
                        .frame(width: 18, height: 14)
                        .padding(0)
                    }
                  }
                  Text(LocalizedStringKey(stringLiteral:line))
                    .font(.system(size: 13.0, weight: .regular, design: design))
                    .id(index)
                  Spacer()
                }
              }
            }
            .background(GeometryReader {
              Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
            })
            .scrollTargetLayout()
            .padding(.bottom, 160)
          } else {
            Text(descLocalizedStringKey)
              .font(.system(size: 13.0, weight: .regular, design: design))
              .foregroundColor(.primary)
              .padding(.trailing, 10)
          }
        }
      }
      .coordinateSpace(name: "scroll")
      .scrollIndicatorsFlash(onAppear: true)
      .mask(LinearGradient(gradient: Gradient(stops: [
        .init(color: Color.black, location: 0.0),
        .init(color: Color.black, location: 0.7),
        .init(color: Color.clear, location: 1.0)
      ]), startPoint: .top, endPoint: .bottom))
      .scrollPosition(id: $currentItemID, anchor: .top)
      .onChange(of: currentItemID) { oldValue, newValue in
        areasViewModel.scrollItemId = newValue!
        if newValue! > 0 {
          withAnimation(.easeInOut) {
            let imageUrl:String
            
            if areasViewModel.visible == true {
              imageUrl = "\(area.shortName)/Area/\(newValue!)"
            } else {
              imageUrl = "\(area.shortName)/\(placesViewModel.selectedPlace.name)/\(newValue!)"
            }
            
            areasViewModel.areaImageUrl = imageUrl
          }
        }
      }
  }
}


import SwiftUI

