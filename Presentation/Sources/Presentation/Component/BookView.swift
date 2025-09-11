import SwiftUI
import NukeUI
import BookModel

struct BookView: View {
    let title: String
    let author: String
    let imageURL: URL
    let publisher: String
    let imageOnly: Bool

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
            .frame(width: 72, height: 96)

            if !imageOnly {
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
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(4)
    }
}
