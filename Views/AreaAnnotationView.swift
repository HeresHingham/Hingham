//
//  AreaAnnotationView.swift
//  Here's Hingham!
//
//  Created by Cameron Conway on 5/2/25.
//

import SwiftUI

struct AreaAnnotationView: View {
  let area: SchemaV1.Area
  let selected: Bool
  let opacity: Double
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
//    var strokeWidth = 0.75
    var zIndex = -100.0
    let titlePadding = 0.0

    if selected == true {
//      strokeWidth = 2
      zIndex = 100.0
    }
    
    return VStack(spacing: 0) {
      if area.specialCount > 0 {
        Text("\(area.specialCount)")
          .font(.caption2)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding(.horizontal, 6)
          .padding(.vertical, 3)
          .background(.red)
          .clipShape(Capsule())
          .offset(x: 18, y: 12)
          .zIndex(2)
      }
      
      Image("MapIcons/\(area.iconImage)")
        .resizable()
        .scaledToFit()
        .frame(width: 30, height: 30)
        .foregroundColor(.white.opacity(0.95))
        .padding(6)
        .background(.accent)
        .cornerRadius(36)
        .zIndex(zIndex)
        .opacity(opacity)
        .zIndex(0)
      
      Text(area.shortName)
        .padding(.top, titlePadding)
        .font(Font.subheadline)
//        .customStroke(color: colorScheme == .dark ? .clear : .white, width: strokeWidth)
        .zIndex(zIndex)
        .opacity(opacity)
    }
  }
}

//#Preview {
//  ZStack {
//    Color.black.ignoresSafeArea()
//    AreaAnnotationView(title: "Hingham Square", selected: false, opacity: 1.0, filter: 0)
//  }
//}
