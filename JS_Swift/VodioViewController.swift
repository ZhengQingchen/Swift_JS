//
//  VodioViewController.swift
//  JS_Swift
//
//  Created by mac on 15/10/28.
//  Copyright © 2015年 mac. All rights reserved.
//

import UIKit

class VodioViewController: UIViewController {

  @IBOutlet weak var redioWebView: UIWebView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
//    let height:CGFloat = (view.frame.width - 16) * 560 / 315
    
    let baseUrl = "https://www.youtube.com/embed/Rg6GLVUnnpM"
    let stringHtml = "<iframe width=\"\(view.frame.width - 16)\" height=\"\(315)\" src=\"\(baseUrl)?&playsinline=1\" frameborder=\"0\" allowfullscreen></iframe>"
    redioWebView.loadHTMLString(stringHtml, baseURL: nil)
    redioWebView.allowsInlineMediaPlayback = true
  }
}
