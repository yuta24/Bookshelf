import UIKit

final class CaptionView: UIView {
    private let message: UILabel = .init()
    private let button: UIButton = .init(type: .system)

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    private func commonInit() {
        message.text = NSLocalizedString("screen.message.no_camera_permission", comment: "")
        message.font = .preferredFont(forTextStyle: .callout)
        message.numberOfLines = 0

        button.setTitle(NSLocalizedString("button.title.open_app_settings", comment: ""), for: .normal)
        button.addAction(.init(handler: { _ in
            UIApplication.shared.open(.init(string: UIApplication.openSettingsURLString)!)
        }), for: .primaryActionTriggered)

        addSubview(message)
        message.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            message.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -24),
            message.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            message.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
        ])

        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 8),
        ])
    }
}
