import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
  @Environment(\.webAuthenticationSession) private var wAS

  var body: some View {
    ZStack {
      Color.Custom.blue.opacity(0.95)
        .ignoresSafeArea()
      VStack {
        Spacer()
        Text("Vinventory")
          .foregroundStyle(Color.Custom.white)
          .font(.largeTitle)
          .bold()
          .padding(.top)
        Spacer()
        Button(action: {
          AuthenticationViewModel(wAS: wAS).loginWithMicrosoft()
        }, label: {
          Text("Login with Microsoft")
            .foregroundStyle(Color.Custom.blue.opacity(0.95))
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(Color.Custom.white)
            )
        })
        .padding(.bottom, 20)
      }
    }
  }
}
