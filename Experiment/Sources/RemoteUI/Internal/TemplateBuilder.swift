import SwiftUI

struct TemplateView<Payload: TemplateParameters> {
    let template: String
    let payload: Payload

    func make() -> some View {
        Text("Hello, world!")
    }
}
