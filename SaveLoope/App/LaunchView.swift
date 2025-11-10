//
//  LaunchView.swift
//  SaveLoope
//
//  Created by 김태성 on 11/10/25.
//

import SwiftUI

struct LaunchView: View {
    var body: some View {
        ZStack {
            // 배경색 설정 (#F5F4F0)
            Color(red: 245/255, green: 244/255, blue: 240/255)
                .ignoresSafeArea()

            // 중앙보다 위에 이미지 배치
            Image("LaunchImage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300, maxHeight: 300)
                .offset(y: -80)
        }
    }
}

#Preview {
    LaunchView()
}
