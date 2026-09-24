//
//  Coordinate2D.swift
//  Here's Hingham!
//
//  Created by Cameron Conway on 4/21/25.
//

struct Coordinate2D: Codable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
