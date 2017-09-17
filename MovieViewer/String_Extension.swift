//
//  String_Extension.swift
//  MovieViewer
//
//  Created by John Nguyen on 9/15/17.
//  Copyright © 2017 John Nguyen. All rights reserved.
//

import Foundation

extension String {
    
    func contains(_ find: String) -> Bool{
        return self.range(of: find) != nil
    }
    
    func containsIgnoreCase(_ find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
}
