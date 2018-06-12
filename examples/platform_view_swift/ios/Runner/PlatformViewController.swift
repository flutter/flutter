// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import UIKit
import Foundation

protocol PlatformViewControllerDelegate
{
	func didUpdateCounter(counter: Int)
}

class PlatformViewController : UIViewController
{
	var delegate: PlatformViewControllerDelegate? = nil
	var counter: Int = 0

	@IBOutlet weak var backButton: UIButton!
	@IBOutlet weak var incrementLabel: UILabel!

	override func viewDidLoad()
	{
		super.viewDidLoad()
		setIncrementLabelText()
	}

	func handleIncrement()
	{
		self.counter += 1
		self.setIncrementLabelText()
	}

	@IBAction func buttonPressed(_ sender: Any)
	{
		dismiss(animated:true, completion:nil)
	}
	
	func switchToFlutterView()
	{
//		self.delegate?.didUpdateCounter(counter: self.counter)
		dismiss(animated:false, completion:nil)
	}

	func setIncrementLabelText()
	{
//		NSString* text = [NSString stringWithFormat:@"Button tapped %d %@.", self.counter, (self.counter == 1) ? @"time" : @"times"];
//		self.incrementLabel.text = text;
	}
}
