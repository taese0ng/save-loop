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
            // 배경색 설정 (라이트/다크 모드 자동 대응)
            Color("LaunchBackground")
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
