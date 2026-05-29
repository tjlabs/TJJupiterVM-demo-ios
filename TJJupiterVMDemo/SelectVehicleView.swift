import UIKit

class SelectVehicleView: UIView {
    
    var onTapOK: (() -> Void)?
    var onTapClose: (() -> Void)?
    
    private let parkingLocationLevelId: Int
    private let parkingLocationId: String
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.6
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let bottomSheetView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()
    
    private var bottomSheetBottomConstraint: NSLayoutConstraint?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "SelectVehicle"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    private let parkingLocationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .darkGray
        return label
    }()

    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 12
        return stackView
    }()

    private let okButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("OK", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Close", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        button.backgroundColor = .systemGray5
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        return button
    }()
    private let bottomSheetHeightRatio: CGFloat = 0.4
    private var bottomSheetHeight: CGFloat {
        bounds.height * bottomSheetHeightRatio
    }
    
    init(levelId: Int, parkingLocationId: String) {
        self.parkingLocationLevelId = levelId
        self.parkingLocationId = parkingLocationId
        super.init(frame: .zero)
        setupLayout()
        bindActions()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bottomSheetBottomConstraint?.constant ?? 0 > 0,
           superview == nil || window == nil {
            bottomSheetBottomConstraint?.constant = bottomSheetHeight
        }
    }
    
    func setupLayout() {
        // Dim background
        addSubview(containerView)
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Bottom sheet
        addSubview(bottomSheetView)
        bottomSheetBottomConstraint = bottomSheetView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: bounds.height * bottomSheetHeightRatio)
        NSLayoutConstraint.activate([
            bottomSheetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSheetBottomConstraint!,
            bottomSheetView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: bottomSheetHeightRatio)
        ])
        bottomSheetView.addSubview(titleLabel)
        bottomSheetView.addSubview(parkingLocationLabel)
        bottomSheetView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(closeButton)
        buttonStackView.addArrangedSubview(okButton)
        
        parkingLocationLabel.text = """
        parkingLocationLevelId: \(parkingLocationLevelId)
        parkingLocationId: \(parkingLocationId)
        """

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: bottomSheetView.topAnchor, constant: 30),
            titleLabel.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20),
            
            parkingLocationLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            parkingLocationLabel.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 20),
            parkingLocationLabel.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -20),

            buttonStackView.leadingAnchor.constraint(equalTo: bottomSheetView.leadingAnchor, constant: 30),
            buttonStackView.trailingAnchor.constraint(equalTo: bottomSheetView.trailingAnchor, constant: -30),
            buttonStackView.bottomAnchor.constraint(equalTo: bottomSheetView.bottomAnchor, constant: -30),
            buttonStackView.heightAnchor.constraint(equalToConstant: 52)
        ])
        containerView.alpha = 0.0
    }
    
    func bindActions() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleBottomSheetPan(_:)))
        bottomSheetView.addGestureRecognizer(panGesture)
        closeButton.addTarget(self, action: #selector(handleCloseButtonTap), for: .touchUpInside)
        okButton.addTarget(self, action: #selector(handleOKButtonTap), for: .touchUpInside)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleContainerTap))
        containerView.addGestureRecognizer(tapGesture)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            layoutIfNeeded()
            presentBottomSheet(animated: true)
        }
    }

    private func presentBottomSheet(animated: Bool) {
        containerView.alpha = 0.0
        bottomSheetBottomConstraint?.constant = 0
        if animated {
            UIView.animate(withDuration: 0.3,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: 0.8,
                           options: [.curveEaseOut]) {
                self.containerView.alpha = 0.6
                self.layoutIfNeeded()
            }
        } else {
            containerView.alpha = 0.6
            layoutIfNeeded()
        }
    }

    private func dismissBottomSheet(animated: Bool, shouldNotifyClose: Bool = true) {
        bottomSheetBottomConstraint?.constant = bottomSheetHeight
        let animations = {
            self.containerView.alpha = 0.0
            self.layoutIfNeeded()
        }
        let completion: (Bool) -> Void = { _ in
            if shouldNotifyClose {
                self.onTapClose?()
            }
            self.removeFromSuperview()
        }

        if animated {
            UIView.animate(withDuration: 0.25,
                           delay: 0,
                           options: [.curveEaseIn],
                           animations: animations,
                           completion: completion)
        } else {
            animations()
            completion(true)
        }
    }

    @objc private func handleOKButtonTap() {
        onTapOK?()
    }

    @objc private func handleCloseButtonTap() {
        dismissBottomSheet(animated: true)
    }

    @objc private func handleContainerTap() {
        dismissBottomSheet(animated: true)
    }

    @objc private func handleBottomSheetPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        let velocity = gesture.velocity(in: self)
        let proposedConstant = max(0, translation.y)

        switch gesture.state {
        case .changed:
            bottomSheetBottomConstraint?.constant = proposedConstant
            let progress = min(1.0, proposedConstant / max(bottomSheetHeight, 1))
            containerView.alpha = 0.6 * (1.0 - progress)

        case .ended, .cancelled, .failed:
            let shouldDismiss = proposedConstant > bottomSheetHeight * 0.3 || velocity.y > 1200
            if shouldDismiss {
                dismissBottomSheet(animated: true)
            } else {
                bottomSheetBottomConstraint?.constant = 0
                UIView.animate(withDuration: 0.25,
                               delay: 0,
                               usingSpringWithDamping: 0.9,
                               initialSpringVelocity: 0.8,
                               options: [.curveEaseOut]) {
                    self.containerView.alpha = 0.6
                    self.layoutIfNeeded()
                }
            }

        default:
            break
        }
    }
}
