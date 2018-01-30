//
//  RoundedShadowButton.swift
//  vision-app
//
//  Created by Aziz on 21/01/2018.
//  Copyright © 2018 vision-coreml. All rights reserved.
//

import UIKit

class RoundedShadowButton: UIButton {

    override func awakeFromNib() {
        
        self.layer.shadowColor = UIColor.gray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.75
        self.layer.cornerRadius = self.frame.height / 2
    }

}
