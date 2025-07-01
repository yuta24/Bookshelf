import SwiftUI
import NukeUI
import BookModel

struct SearchingBookView: View {
    let title: String
    let author: String
    let imageURL: URL
    let publisher: String
    let registered: Bool?

    var body: some View {
        HStack(alignment: .top) {
            LazyImage(url: imageURL) { state in
                if let image = state.image {
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Color.gray
                }
            }
            .frame(width: 90, height: 120)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .lineLimit(3)

                VStack(alignment: .leading) {
                    Text(author)
                        .font(.footnote)
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineLimit(1)

                    Text(publisher)
                        .font(.footnote)
                        .foregroundStyle(Color(.secondaryLabel))
                        .lineLimit(1)

                    Spacer()

                    if let registered {
                        Text(registered ? "registered" : "unregistered")
                            .fontWeight(registered ? .bold : .regular)
                            .font(.footnote)
                            .foregroundStyle(registered ? Color(.label) : Color(.secondaryLabel))
                            .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(4)
    }
}
