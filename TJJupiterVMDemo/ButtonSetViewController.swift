//
//  ButtonSetViewController.swift
//  TJJupiterVMDemo
//
//  Created by leo.shin on 8/26/26.
//

import UIKit

class ButtonSetViewController: UIViewController {

    private let enabledButtonColor = UIColor(hex: "#E47325")

    private lazy var indoorMapButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("실내 지도", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = enabledButtonColor
        button.layer.cornerRadius = 14
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.16
        button.layer.shadowOffset = CGSize(width: 0, height: 8)
        button.layer.shadowRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(indoorMapTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "TJJupiterVM Demo"

        view.addSubview(indoorMapButton)

        NSLayoutConstraint.activate([
            indoorMapButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indoorMapButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            indoorMapButton.widthAnchor.constraint(equalToConstant: 200),
            indoorMapButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }

    @objc private func indoorMapTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let mainVC = storyboard.instantiateViewController(withIdentifier: "MainViewController")
        navigationController?.pushViewController(mainVC, animated: true)
    }
}
