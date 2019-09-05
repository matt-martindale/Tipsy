//
//  PlatterViewController.swift
//  tipTester
//
//  Created by Marlon Raskin on 9/1/19.
//  Copyright © 2019 Marlon Raskin. All rights reserved.
//

import UIKit
import CoreMotion

class PlatterViewController: UIViewController {

	enum PlatterPosition {
		case right
		case left
	}

	@IBOutlet weak var eachLabel: UILabel!
	@IBOutlet weak var eachDescLabel: UILabel!
	@IBOutlet weak var totalLabel: UILabel!
	@IBOutlet weak var totalDescLabel: UILabel!
	@IBOutlet weak var blurEffectView: UIVisualEffectView!
	@IBOutlet weak var platterView: UIView!
	@IBOutlet weak var dismissButton: UIButton!
	@IBOutlet weak var partyCountLabelContainer: UIView!
	@IBOutlet weak var partyCountLabel: UILabel!
	@IBOutlet weak var trailingAnchor: NSLayoutConstraint!
	@IBOutlet weak var leadingAnchor: NSLayoutConstraint!
	@IBOutlet weak var stepper: UIStepper!
	@IBOutlet weak var tipLabel: UILabel!
	@IBOutlet weak var tipDescLabel: UILabel!

	let generator = UIImpactFeedbackGenerator(style: .medium)
	var themeHelper: ThemeHelper?
	let motionManager = CMMotionManager()
	var logic: CalculatorLogic?
	var totalAmount: String?
	var originalTotal: String?
	var eachAmount: Double = 0.00
	var partyCount: Int = 1 {
		didSet {
			partyCountLabel.text = "\(partyCount)"
		}
	}

	lazy var motionChecker: Timer = {
		let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
			guard let self = self else {
				timer.invalidate()
				return
			}
			self.updateAccelerometerData()
		}
		return timer
	}()


	var isDarkStatusBar = false {
		didSet {
			UIView.animate(withDuration: 0.3) {
				self.navigationController?.setNeedsStatusBarAppearanceUpdate()
			}
		}
	}

	override var preferredStatusBarStyle: UIStatusBarStyle {
		return isDarkStatusBar ? .default : .lightContent	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		motionManager.startAccelerometerUpdates()
		_ = motionChecker
		setTheme()
		setStandardUI()
		stepper.minimumValue = 1
		stepper.maximumValue = 10
		calculateSplit()
		generator.prepare()
    }

	deinit {
		print("Deinit")
	}
	

	@IBAction func stepperTapped(_ sender: UIStepper) {
		generator.impactOccurred()
		partyCount = Int(sender.value)
		calculateSplit()
	}

	private func calculateSplit() {
		guard let total = totalAmount else { return }
		guard let divisorValueString = partyCountLabel.text else { return }
		let totalValueString = total.replacingOccurrences(of: "$", with: "")
		let totalValue = Double(totalValueString)
		let divisorValue = Double(divisorValueString)
		if let total = totalValue,
			let divisor = divisorValue,
			let logic = logic {
			let eachValue = total / divisor
			eachAmount = eachValue
			eachLabel.text = "\(logic.currencyFormatter.string(from: NSNumber(value: eachAmount)) ?? "$0.00")"
			let newTotalAmount = getAmountFromEachLabel() * Double(partyCount)
			totalLabel.text = "\(logic.currencyFormatter.string(from: NSNumber(value: newTotalAmount)) ?? "0.00")"
			tipLabel.text = "\(logic.currencyFormatter.string(from: NSNumber(value: newTipAmount(newTotal: newTotalAmount))) ?? "0.00")"
		}

	}

	private func getAmountFromEachLabel() -> Double {
		guard let stringValueFromEachLabel = eachLabel.text else { return 0.00 }
		let cleanStringFromEachValueLabel = stringValueFromEachLabel.replacingOccurrences(of: "$", with: "")
		let cleanEachValue = Double(cleanStringFromEachValueLabel)
		guard let eachValueUnwrapped = cleanEachValue else { return 0.00 }
		return eachValueUnwrapped
	}

	private func newTipAmount(newTotal: Double) -> Double {
		guard let originalTotalString = originalTotal else { return 0.00 }
		let originalTotalValue = Double(originalTotalString)
		guard let total = originalTotalValue else { return 0.00 }
		return newTotal - total
	}

	@IBAction func switchSides(_ sender: UIButton) {
		UIView.animate(withDuration: 0.5) {
			self.trailingAnchor.isActive.toggle()
			self.leadingAnchor.isActive = !self.trailingAnchor.isActive
			self.view.layoutIfNeeded()
		}
	}

	func animateIn() {
		view.alpha = 0
		view.transform = CGAffineTransform(scaleX: 4.0, y: 4.0)
		UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 2.0, initialSpringVelocity: 5.0, options: [.curveEaseInOut], animations: {
			self.view.transform = .identity
			self.view.alpha = 1
		}, completion: nil)
	}

	func animateOut(completion: @escaping (Bool) -> Void) {
		UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 2.0, initialSpringVelocity: 5.0, options: [.curveEaseInOut], animations: {
			self.view.transform = CGAffineTransform(scaleX: 5.0, y: 2.5)
			self.view.alpha = 0
		}, completion: completion)
	}

	func movePlatter(to destination: PlatterPosition) {
		guard (destination == .right && !trailingAnchor.isActive) ||
		(destination == .left && trailingAnchor.isActive) else {
			return
		}
		switch destination {
		case .right:
			leadingAnchor.isActive = false
			trailingAnchor.isActive = true
		case .left:
			trailingAnchor.isActive = false
			leadingAnchor.isActive = true
		}
		UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 5.0, initialSpringVelocity: 2.0, options: [.curveEaseInOut], animations: {
			self.view.layoutIfNeeded()
		}, completion: nil)
	}

	@IBAction func tapToDismiss(_ sender: UITapGestureRecognizer) {
		dismissView()
	}

	@IBAction func dismissTapped(_ sender: UIButton) {
		dismissView()
	}

	func updateAccelerometerData() {
		if let accelerometerData = motionManager.accelerometerData {
			let threshold = 0.4
			if accelerometerData.acceleration.x < -threshold {
				movePlatter(to: .left)
			} else if accelerometerData.acceleration.x > threshold {
				movePlatter(to: .right)
			}
		}
	}

	func dismissView(animated: Bool = true) {
		if animated {
			animateOut { _ in
				self.view.removeFromSuperview()
				self.removeFromParent()
			}
		} else {
			view.removeFromSuperview()
			removeFromParent()
		}
	}

	private func setStandardUI() {
		loadViewIfNeeded()
		dismissButton.layer.cornerRadius = dismissButton.frame.height / 2
		partyCountLabel.text = "1"
		partyCountLabelContainer.layer.cornerRadius = partyCountLabelContainer.frame.height / 2
		platterView.layer.cornerRadius = 12
		dismissButton.setTitleColor(.mako2, for: .normal)
		guard let total = totalAmount else { return }
		totalLabel.text = "\(total)"
	}


	private func setTheme() {
		guard let themeHelper = themeHelper else { return }
		switch themeHelper.themePreference {
		case .light:
			let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
			blurEffectView.effect = UIVibrancyEffect(blurEffect: blurEffect, style: .quaternaryLabel)
			blurEffectView.effect = UIBlurEffect(style: .light)
			platterView.backgroundColor = .wildSand
			platterView.layer.shadowColor = UIColor.lightGray.cgColor
			platterView.layer.shadowRadius = 14
			platterView.layer.shadowOpacity = 0.4
			partyCountLabelContainer.backgroundColor = .white
			dismissButton.backgroundColor = .turquoiseTwo
			eachLabel.textColor = .mako2
			totalLabel.textColor = .mako2
			tipLabel.textColor = .mako2
			eachDescLabel.textColor = .mako
			tipDescLabel.textColor = .mako
			totalDescLabel.textColor = .mako
			partyCountLabel.textColor = .mako2
			stepper.overrideUserInterfaceStyle = .light

		case .dark:
			platterView.backgroundColor = .darkJungleGreen
			partyCountLabelContainer.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0)
			partyCountLabel.textColor = .wildSand
			dismissButton.backgroundColor = .turquoise
			let blurEffect = UIBlurEffect(style: .systemThinMaterialDark)
			blurEffectView.effect = UIVibrancyEffect(blurEffect: blurEffect, style: .secondaryFill)
			blurEffectView.effect = UIBlurEffect(style: .dark)
			eachLabel.textColor = .wildSand
			totalLabel.textColor = .wildSand
			tipLabel.textColor = .wildSand
			eachDescLabel.textColor = .lightGray
			totalDescLabel.textColor = .lightGray
			tipDescLabel.textColor = .lightGray
			stepper.overrideUserInterfaceStyle = .dark
		}
	}
}
