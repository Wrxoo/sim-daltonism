
//	Copyright 2005-2016 Michel Fortin
//
//	Licensed under the Apache License, Version 2.0 (the "License");
//	you may not use this file except in compliance with the License.
//	You may obtain a copy of the License at
//
//	http://www.apache.org/licenses/LICENSE-2.0
//
//	Unless required by applicable law or agreed to in writing, software
//	distributed under the License is distributed on an "AS IS" BASIS,
//	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//	See the License for the specific language governing permissions and
//	limitations under the License.

import Cocoa

class AboutBoxBackground: NSView {
	override var isOpaque: Bool { return true }
	override var mouseDownCanMoveWindow: Bool { return true }
	override func draw(_ dirtyRect: NSRect) {
		let rect = bounds
		let gradient = NSGradient(starting: NSColor.white(), ending: NSColor(calibratedWhite: 0.9, alpha: 1.0))
		gradient?.draw(from: NSPoint(x: 0, y: rect.maxY), to: NSPoint(x: 0, y: rect.minY), options: NSGradientDrawingOptions(rawValue: UInt(0)))
	}
}

class AboutBoxIconView: NSImageView {
	override var mouseDownCanMoveWindow: Bool { return true }
}

class AboutBoxScrollView: NSScrollView {
	override var scrollerStyle: NSScrollerStyle {
		get { return super.scrollerStyle }
		set {
			// Fix for an issue where the view offset is changed when setting scroller style
			let point = contentView.bounds.origin
			super.scrollerStyle = newValue
			documentView?.scroll(point)
		}
	}
}

extension NSApplication {

	@IBAction func orderFrontAboutBox(_ sender: AnyObject) {
		AboutBoxController.sharedAboutBoxController.showWindow(sender)
	}

}

class AboutBoxController: NSWindowController {

	static var sharedAboutBoxController = AboutBoxController()

	@IBOutlet var iconView: NSImageView!
	@IBOutlet var textView: NSTextView!

	@NSCopying private var templateText: AttributedString? {
		didSet { updateText() }
	}

	override var windowNibName: String {
		return "AboutBox"
	}

	override func windowDidLoad() {
		window!.styleMask.formUnion(NSFullSizeContentViewWindowMask)
		window!.titlebarAppearsTransparent = true
		window!.isMovableByWindowBackground = true

		templateText = textView.attributedString()

		// Adjust scroll view rect to fill superview bounds, but apply margins
		// to text container to preserve the rectangle for visible text
		var inset = textView.textContainerInset
		var frame = textView.enclosingScrollView!.frame
		let bounds = window!.contentView!.bounds
		let addedWidth = bounds.size.width - frame.maxX
		let addedHeight = bounds.size.height - frame.maxY
		inset.width += addedWidth
		inset.height += addedHeight
		frame.insetInPlace(dx: -addedWidth, dy: 0)
		frame.size.height = bounds.size.height
		frame.origin.y = bounds.origin.y
		textView.enclosingScrollView!.frame = frame
		textView.textContainerInset = inset
		textView.scrollToBeginningOfDocument(nil)

		super.windowDidLoad()
	}

	func updateText() {
		textView.textStorage?.setAttributedString(standardTextContent)
	}

	var appName: String {
		let mainBundle = Bundle.main
		if let name = mainBundle.objectForInfoDictionaryKey(kCFBundleNameKey as String) as? String {
			return name
		} else {
			return mainBundle.bundleURL.lastPathComponent!
		}
	}

	var appVersionWithBuildNumber: String {
		let mainBundle = Bundle.main
		let version = mainBundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String ?? "?"
		let build = mainBundle.objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String

		if let build = build where build != version {
			return "\(version) (\(build))"
		} else {
			return version
		}
	}

	var appVersion: String {
		return "Version \(appVersionWithBuildNumber)"
	}

	var appCopyright: String {
		return Bundle.main.objectForInfoDictionaryKey("NSHumanReadableCopyright") as? String ?? ""
	}

	var appCredits: AttributedString {
		for ext in ["html", "rtf", "rtfd"] {
			if let creditsURL = Bundle.main.urlForResource("Credits", withExtension: ext) {
				let credits = try! AttributedString(url: creditsURL, options: [:], documentAttributes: nil)
				return credits
			}
		}
		return AttributedString() // credits not found
	}

	var standardTextContent: AttributedString {
		guard let templateText = self.templateText else { return AttributedString() }

		let textString = templateText.string as NSString
		let appRange = textString.range(of: "App")
		let versionRange = textString.range(of: "Version")
		let copyrightRange = textString.range(of: "Copyright")
		let creditsRange = textString.range(of: "Credits")

		let finalText = templateText.mutableCopy() as! NSMutableAttributedString

		// Replace from last to first so ranges stay valid after each replacement
		finalText.replaceCharacters(in: creditsRange, with: appCredits)
		finalText.replaceCharacters(in: copyrightRange, with: appCopyright)
		finalText.replaceCharacters(in: versionRange, with: appVersion)
		finalText.replaceCharacters(in: appRange, with: appName)

		return finalText
	}

	override func showWindow(_ sender: AnyObject?) {
		if !window!.isVisible {
			textView.scroll(NSZeroPoint)
			window!.center()
		}
		super.showWindow(sender)

		textView.enclosingScrollView?.flashScrollers()
	}

}
