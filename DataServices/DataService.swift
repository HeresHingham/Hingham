//
//  LocationsDataService.swift
//  MapTest
//
//  Created by Nick Sarno on 11/26/21.
//

import Foundation
import MapKit
import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseFirestore
import Alamofire
import CDYelpFusionKit

class DataService {
  @State var name = ""
  public static var yelpAPIClient = CDYelpAPIClient(apiKey: "iQQOaKrSKp4-7jORkK8tYfQiUxHIn78-HefSRafOvFG-AvvoNRwjQhj4_Kb0mqX3IOM__qcUBApaUcTY-YZQLHWY2THQxsiZjKV5zoSD0tcZP5GCCCfFJclGTX33Y3Yx")
  
  func updateYelp(name: String) {
    self.name = name
    let db = Firestore.firestore()
    
    db.collection("HinghamPlace").whereField("name", isEqualTo: name).getDocuments { queryPlace, err in
      for place:QueryDocumentSnapshot in queryPlace!.documents {
        let yelpId = place.get("yelpId") as! String
        if yelpId == "" {
          self.updateYelpData(place: place)
        }
      }
    }
  }
  
  func updateYelpData(place: QueryDocumentSnapshot) {
    if let name = place.get("name") as? String {
      let db = Firestore.firestore()
      var seconds:Double = 0.0
      let latitude = place.get("locationLat") as! Double
      let longitude = place.get("locationLng") as! Double
      seconds += 5.0
      
      DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        DataService.yelpAPIClient.searchBusinesses(byTerm: name, location: "Hingham, MA", latitude: latitude, longitude: longitude, radius: 1000, categories: nil, locale: nil, limit: 1, offset: nil, sortBy: nil, priceTiers: nil, openNow: nil, openAt: nil, attributes: nil) { business in
          if let business = business {
            if let businesses = business.businesses {
              businesses.forEach { businessSearch in
                let id = businessSearch.alias
                let rating = businessSearch.rating
                let reviews = businessSearch.reviewCount
                let phone = businessSearch.displayPhone
                let price = businessSearch.price
                let address = businessSearch.location!.addressOne
                let url = businessSearch.url
                var categoryList = ""
                if let categories = businessSearch.categories {
                  categories.forEach { category in
                    if categoryList == "" {
                      categoryList = category.title!
                    } else {
                      categoryList += ", " + category.title!
                    }
                  }
                }
                
                let documentId = place.documentID
                
                db.collection("HinghamPlace").document(documentId).updateData(["yelpId":id ?? "", "yelpRating":rating ?? 0.0, "yelpReviews":reviews ?? 0, "phone":phone ?? "", "yelpPrice":price ?? "", "yelpUrl":url ?? "", "yelpCategory":categoryList, "address":address ?? ""]) { err in
                  if let err = err {
                    print("Error writing document: \(err)")
                  }
                }
              }
            }
          }
        }
      }
    }
  }
  
  func updateGoogle(name: String) {
    self.name = name
    let db = Firestore.firestore()
    
    db.collection("HinghamPlace").whereField("name", isEqualTo: name).getDocuments { queryPlace, err in
      for place in queryPlace!.documents {
        let googleId = place.get("googleId") as! String
        let documentId = place.documentID
        self.updateGoogleData(googlePlaceId: googleId, requestId: nil, updateType: "Data", documentId: documentId)
      }
    }
  }
  
  func updateGoogleData(googlePlaceId:String, requestId:String?, updateType:String, documentId:String) {
    var url = URL(string:"about:blank")!
    let headers: HTTPHeaders = ["Content-type": "application/x-www-form-urlencoded", "X-API-KEY": "YXV0aDB8NjQxMDc3ZjRjYjNiYWE4Yjg5M2Y0MmUwfDFjZTEzM2IyNGQ"]
    
    if let requestId = requestId {
      url = URL(string: "https://api.app.outscraper.com/requests/\(requestId)")!
    } else {
      url = URL(string: "https://api.app.outscraper.com/maps/reviews-v3?query=\(googlePlaceId)&reviewsLimit=1&sort=newest&ignoreEmpty=true")!
    }
    
    do {
      let urlRequest = try URLRequest(url: url, method: .get, headers: headers)
      getData(from: urlRequest) { data, response, error in
        guard let data = data, error == nil else {
          return
        }
        do {
          if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let status = json["status"] as? String {
              if status == "Pending" {
                if let id = json["id"] as? String {
                  self.updateGoogleData(googlePlaceId: googlePlaceId, requestId: id, updateType: updateType, documentId: documentId)
                }
              } else if status == "Success" {
                let db = Firestore.firestore()
                
                if let jsonData = json["data"] as? [[String:Any]], jsonData.count > 0 {
                  let rating = jsonData[0]["rating"] as? Double ?? 0.0
                  let reviews = jsonData[0]["reviews"] as? Int ?? 0
                  let googleUrl = jsonData[0]["owner_link"] as? String ?? ""
                  let website = jsonData[0]["site"] as? String ?? ""
                  let notes = jsonData[0]["description"] as? String ?? ""
                  var allHours = ""
                  
                  if let workingHours = jsonData[0]["working_hours"] as? [String:Any] {
                    var hours = workingHours["Sunday"] as! String
                    hours = "0,\(hours.replacingOccurrences(of: "\\U202f", with: " "));"
                    allHours = hours
                    hours = workingHours["Monday"] as! String
                    allHours += "1,\(hours.replacingOccurrences(of: "\\U202f", with: " "));"
                    hours = workingHours["Tuesday"] as! String
                    allHours += "2,\(hours.replacingOccurrences(of: "\\U202f", with: " "));"
                    hours = workingHours["Wednesday"] as! String
                    allHours += "3,\(hours.replacingOccurrences(of: "\\U202f", with: " "));"
                    hours = workingHours["Thursday"] as! String
                    allHours += "4,\(hours.replacingOccurrences(of: "\\U202f", with: " "));"
                    hours = workingHours["Friday"] as! String
                    allHours += "5,\(hours.replacingOccurrences(of: "\\U202f", with: " "));"
                    hours = workingHours["Saturday"] as! String
                    allHours += "6,\(hours.replacingOccurrences(of: "\\U202f", with: " "))"
                  }
                  
                  db.collection("HinghamPlace").document(documentId).updateData(["googleRating":rating, "googleReviews":reviews, "googleUrl":googleUrl, "website":website, "notes":notes, "hours":allHours]) { err in
                    if let err = err {
                      print("Error writing document: \(err)")
                    } else {
//                    UIImageView.reviewCount += 1
//                    setMessage("Processed Google \(updateType) for \(placeName)")
//                    deleteGoogleReviews(googlePlaceId: googlePlaceId)
                      self.updateGoogleData(googlePlaceId: googlePlaceId, requestId: nil, updateType: "Reviews", documentId: documentId)
                    }
                  }
                }
              } else if status == "Error" {
                print("Error")
              }
            }
          }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
      }
    } catch {
      print(error)
    }
  }

  
  func addGoogleReviews(googlePlaceId:String, requestId:String?) {
    var url = URL(string:"about:blank")!
    let headers: HTTPHeaders = ["Content-type": "application/x-www-form-urlencoded", "X-API-KEY": "YXV0aDB8NjQxMDc3ZjRjYjNiYWE4Yjg5M2Y0MmUwfDFjZTEzM2IyNGQ"]
    
    if let requestId = requestId {
      url = URL(string: "https://api.app.outscraper.com/requests/\(requestId)")!
    } else {
      let fieldList = "status,id,name,reviews_data"
      url = URL(string: "https://api.app.outscraper.com/maps/reviews-v3?query=\(googlePlaceId)&fields=\(fieldList)&reviewsLimit=5&sort=newest&ignoreEmpty=true")!
    }
    
    do {
      let urlRequest = try URLRequest(url: url, method: .get, headers: headers)
      getData(from: urlRequest) { data, response, error in
        guard let data = data, error == nil else {
//          setMessage("Processed Google \(UIImageView.reviewCount) of \(UIImageView.reviewTotal)")
          return
        }
        do {
          if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let status = json["status"] as? String {
              if status == "Pending" {
                if let id = json["id"] as? String {
                  self.addGoogleReviews(googlePlaceId: googlePlaceId, requestId: id)
                }
              } else if status == "Success" {
                let db = Firestore.firestore()
                
                if let jsonData = json["data"] as? [[String:Any]], jsonData.count > 0 {
                  if let reviewsData = jsonData[0]["reviews_data"] as? [[String:Any]] {
                    var acceptedReviewCount = 0
                    for review in reviewsData {
                      var reviewText = ""
                      if let text = review["review_text"] as? String {
                        reviewText = text
                      }
                      if let ownerAnswer = review["owner_answer"] as? String {
                        reviewText += "<br/><br/><strong>Owner Response</strong><br/><br/>" + ownerAnswer
                      }
                      if reviewText.count > 20 && acceptedReviewCount < 6 {
                        acceptedReviewCount += 1
                        let authorImage = review["author_image"] as? String ?? ""
                        let authorName = review["author_title"] as! String
                        let reviewRating = review["review_rating"] as! Double
                        let reviewLink = review["review_link"] as! String
                        let reviewDate = (review["review_datetime_utc"] as! String).components(separatedBy: " ")[0]
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                        dateFormatter.dateFormat = "MM/dd/yyyy"
                        let reviewDateTimestamp = Timestamp(date: dateFormatter.date(from:reviewDate)!)
                        
                        db.collection("GoogleReview").addDocument(data: [
                          "GooglePlaceId" : googlePlaceId,
                          "AuthorImage" : authorImage,
                          "AuthorName" : authorName,
                          "ReviewDate": reviewDateTimestamp,
                          "Rating" : reviewRating,
                          "Text" : reviewText,
                          "Link" : reviewLink
                        ]) { err in
                          if let err = err {
                            print("Error adding document: \(err)")
                          }
                        }
                      } else {
//                        setMessage("Added Google Reviews")
                      }
                    }
                    if acceptedReviewCount < 6 {
//                      setMessage("Done adding Google Reviews")
                    }
                  }
                }
              } else if status == "Error" {
                print("Error")
              }
            }
          }
        } catch let error as NSError {
            print("Failed to load: \(error.localizedDescription)")
        }
      }
    } catch {
      print(error)
    }
  }
  
  func getData(from url: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
      URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
  }
}
