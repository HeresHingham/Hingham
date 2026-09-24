//
//  BusinessesViewModel.swift
//  Here's Hingham!
//
//  Created by Cameron Conway on 5/7/25.
//

import Foundation
import MapKit
import SwiftUI
import SwiftData

class PlacesViewModel: ObservableObject {
  @Published var places: [SchemaV1.Place] = []
  @Published var tourPlaces: [SchemaV1.TourPlace] = []
  @Published var selectedPlace: SchemaV1.Place
  @Published var visible = false
  
  init() {
    selectedPlace = SchemaV1.Place()
  }
  
  public func addPlace(_ place: SchemaV1.Place) {
    places.append(place)
  }
  
  public func addTourPlace( _ tourPlace: SchemaV1.TourPlace) {
    tourPlaces.append(tourPlace)
  }
  
  public func isBucketPointList(place: SchemaV1.Place) -> Bool {
    return place.name == "Iron Horse Statue" || place.name == "No Noise Hingham"
  }
    
  func setPlaceSelected(_ area: SchemaV1.Area, _ place: SchemaV1.Place) {
    if selectedPlace == place && (selectedPlace.selected == true || place.selected == true) {
      place.selected = false
    } else {
      selectedPlace.selected = false
      place.selected = place.name != ""
    }
    
    withAnimation(.easeInOut) {
      selectedPlace = place
    }
    
    if place.imageCount == 0 {
      var imageCounter = 0
      let placeName = place.name == "" ? "Area" : place.name
      while UIImage(named: ("\(area.shortName)/\(placeName)/\(imageCounter)")) != nil {
        imageCounter += 1
      }
      if placeName == "Area" {
        area.imageCount = imageCounter
        visible = false
      } else {
        place.imageCount = imageCounter
        visible = true
      }
    } else {      
      visible = true
    }
  }
}

