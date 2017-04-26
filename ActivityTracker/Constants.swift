//
//  Constants.swift
//  ActivityTracker
//
//  Created by Stephen Schiffli on 4/26/17.
//  Copyright © 2017 MBIENTLAB Inc. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}

//
// MARK: - Navigation
//
let ColorNavigationBarTint = UIColor(rgb: 0x0D0D0D)
let ColorNavigationTint = UIColor(rgb: 0xFF7500)
let ColorNavigationTitle = UIColor(rgb: 0xFF7500)
//
// MARK: - Bar Chart
//
let ColorBarChartControllerBackground = UIColor(rgb: 0x313131)
let ColorBarChartBackground = UIColor(rgb: 0x1F1F1F)
let ColorBarChartBarGreen = UIColor(rgb: 0x52EDC7)
let ColorBarChartBarBlue = UIColor(rgb: 0x5AC8FB)
let ColorBarChartBarRed = UIColor(rgb: 0xFF4B30)
let ColorBarChartBarOrange = UIColor(rgb: 0xFF9500)
let ColorBarChartHeaderSeparatorColor = UIColor(rgb: 0x686868)
//
// MARK: - Tooltips
//
let ColorTooltipColor = UIColor(white: 1.0, alpha: 0.9)
let ColorTooltipTextColor = UIColor(rgb: 0xFF7500)


// MARK: - Navigation
let FontNavigationTitle = UIFont(name: "HelveticaNeue-CondensedBold", size: 20.0)!

// MARK: - Footers
let FontFooterLabel = UIFont(name: "HelveticaNeue-Light", size: 12.0)!
let FontFooterSubLabel = UIFont(name: "HelveticaNeue", size: 10.0)!

// MARK: - Headers
let FontHeaderTitle = UIFont(name: "HelveticaNeue-Bold", size:20)!
let FontHeaderSubtitle = UIFont(name: "HelveticaNeue-Light", size:14)!

// MARK: - Information
let FontInformationTitle = UIFont(name: "HelveticaNeue", size:18)!
let FontInformationValue = UIFont(name: "HelveticaNeue-CondensedBold", size:50)!
let FontInformationUnit = UIFont(name: "HelveticaNeue", size:30)!

// MARK: - Tooltip
let FontTooltipText = UIFont(name: "HelveticaNeue-Bold", size:14)!
