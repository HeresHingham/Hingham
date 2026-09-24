//
//  RatingsView.swift
//  Here's Hingham!
//
//  Created by Cameron Conway on 7/3/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct RatingsView: View {
  @Binding var place: SchemaV1.Place
  @Binding var showRatingSelector: Bool
  @State var rating: Double = 0.0
  @State var width = UIDevice.current.userInterfaceIdiom == .pad ? UIScreen.main.bounds.size.width * 0.373 : UIScreen.main.bounds.size.width * 0.86
  
  var label = "How many stars?"
  var maximumRating: Double = 5.0
  
  var offImage: Image?
  var starImage = Image("Reviews/StarRater")
  var halfStarImage = Image("Reviews/HalfStarRater")
  let start = 1.0
  
  var offColor = Color.gray
  var onColor = Color.yellow
  
  var body: some View {
    HStack {
      if label.isEmpty == false {
        Text(label)
          .font(.system(size: 12))
      }
      
      ForEach(Array(stride(from: 1.0, through: maximumRating, by: 1.0)), id: \.self) { number in
        Button {
          rating = number
        } label: {
          number > rating ? Image("Reviews/GrayStarRater") : number.truncatingRemainder(dividingBy: 1.0) == 0 ? Image("Reviews/StarRater") : Image("Reviews/GrayHalfStarRater")
        }
        .padding(-2)
      }
      Spacer()
      Button {
        if rating > 0 {
          place.hinghamReviews += 1
          place.hinghamRatings += place.hinghamRatings == "" ? String(rating) : ";" + String(rating)
          place.updateHinghamRating()
          let db = Firestore.firestore()
          let placeRef = db.collection("HinghamPlace").document(place.documentID)
          placeRef.updateData(["hinghamRatings" : place.hinghamRatings, "hinghamReviews" : place.hinghamReviews])
          @AppStorage("Rated:\(place.id)") var rated: String = ""
          rated = "true"
        }
        showRatingSelector = false
      } label: {
        Text("Rate")
          .foregroundStyle(.white)
          .font(.system(size: 13, weight: .bold))
      }
      .buttonStyle(.borderedProminent)
      .tint(.red)
      .padding(.top, 1)
      Button {
        showRatingSelector = false
      } label: {
        Image(systemName: "x.square.fill")
          .font(.system(size: 32))
          .tint(.red)
          .cornerRadius(25)
      }
    }
    .frame(width: width, height: 11)
    .padding(.top, 10)
    .padding(.bottom, 25)
  }
  
  func image(for number: Double) -> Image {
    if number > rating {
      offImage ?? starImage
    } else {
      starImage
    }
  }
}



