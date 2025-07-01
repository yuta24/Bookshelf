import UIKit
import AVFoundation
import OSLog
import Combine

private let logger: Logger = .init(subsystem: "com.bivre.common.scanner", category: "CameraViewController")

final class CameraViewController: UIViewController {
    let onCaptured: (String) -> Void

    private let session: AVCaptureSession = .init()
    private let sessionQueue: DispatchQueue = .init(label: "sessionQueue")
    private let previewView: PreviewView = .init()

    private let metadataOutput: AVCaptureMetadataOutput = .init()

    private let caption: CaptionView = .init()
    private let target: UIView = .init()

    private let stream: PassthroughSubject<String, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator!
    private var observations: Set<NSKeyValueObservation> = .init()

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(onCaptured: @escaping (String) -> Void) {
        self.onCaptured = onCaptured

        super.init(nibName: nil, bundle: nil)

        previewView.videoPreviewLayer.session = session
        previewView.videoPreviewLayer.videoGravity = .resizeAspectFill
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        view.addSubview(caption)
        caption.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            caption.topAnchor.constraint(equalTo: view.topAnchor),
            caption.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            caption.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            caption.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        caption.isHidden = true

        target.backgroundColor = .clear
        target.layer.borderWidth = 2
        target.layer.borderColor = UIColor.white.cgColor
        target.layer.cornerRadius = 4

        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        view.addSubview(target)
        target.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            target.heightAnchor.constraint(equalToConstant: 72),
            target.widthAnchor.constraint(equalToConstant: 180),
            target.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            target.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch Status(status) {
        case .some(.unavailable):
            caption.isHidden = false
        case .some(.available):
            sessionQueue.async { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    self?.configure()
                }
            }
        case .none:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.sessionQueue.async {
                        DispatchQueue.main.async {
                            self?.configure()
                        }
                    }
                } else {
                    self?.caption.isHidden = false
                }
            }
        }

        stream.throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] text in
                self?.onCaptured(text)
            }
            .store(in: &cancellables)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        DispatchQueue.main.async {
            self.updateRectOfInterest()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if !session.isRunning {
            sessionQueue.async { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    self?.session.startRunning()
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if session.isRunning {
            sessionQueue.async { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    self?.session.stopRunning()
                }
            }
        }
    }

    private func configure() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return }
        guard session.canAddInput(deviceInput) else { return }
        guard session.canAddOutput(metadataOutput) else { return }

        session.beginConfiguration()

        session.addInput(deviceInput)
        session.addOutput(metadataOutput)

        let metadataQueue = DispatchQueue(label: "metadataQueue")
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
        metadataOutput.metadataObjectTypes = [.ean13]

        session.commitConfiguration()

        DispatchQueue.main.async {
            self.setupRotationCoordinator(deviceInput.device)
        }
    }

    private func setupRotationCoordinator(_ device: AVCaptureDevice) {
        rotationCoordinator = .init(device: device, previewLayer: previewView.videoPreviewLayer)
        previewView.videoPreviewLayer.connection?.videoRotationAngle = rotationCoordinator.videoRotationAngleForHorizonLevelPreview

        observations.insert(rotationCoordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { [weak self] _, change in
            guard let videoRotationAngleForHorizonLevelPreview = change.newValue else { return }

            self?.previewView.videoPreviewLayer.connection?.videoRotationAngle = videoRotationAngleForHorizonLevelPreview

            DispatchQueue.main.async { [weak self] in
                self?.updateRectOfInterest()
            }
        })
    }

    private func updateRectOfInterest() {
        let rect = previewView.videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: target.frame)

        sessionQueue.async { [weak self] in
            logger.debug("converted frame: \(rect.debugDescription)")
            self?.metadataOutput.rectOfInterest = rect
        }
    }
}

extension CameraViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from _: AVCaptureConnection) {
        for object in metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }) where object.type == .ean13 {
            guard let text = object.stringValue else { return }
            self.stream.send(text)
        }
    }
}
