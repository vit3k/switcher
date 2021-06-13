//
//  Loopcheck.swift
//  testble2
//
//  Created by Pawel Witkowski on 09/06/2021.
//

import SwiftUI

struct Loopcheck: View {
    @Binding var checked: Bool
    var text: String
    var action: () -> Void
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 30, height: 30)
                .foregroundColor(checked ? .green : .gray)
            Text(text)
                .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                .foregroundColor(Color.black)
        }.onTapGesture {
            checked.toggle()
            action()
        }
    }
}

struct Loopcheck_Previews: PreviewProvider {
    @State static var checked: Bool = false
    static var previews: some View {
        Loopcheck(checked: $checked, text: "1") {
            
        }
    }
}
