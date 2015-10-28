//
//  ViewController.swift
//  JS_Swift
//
//  Created by mac on 15/10/26.
//  Copyright © 2015年 mac. All rights reserved.
//

import UIKit
import SwiftyJSON
import SDWebImage
import IDMPhotoBrowser

struct LastWebViewOffset {
  static var offset:CGFloat = 0
}

func backgroundThread(delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
  dispatch_async(dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0)) {
    if(background != nil){ background!() }
    
    let popTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(popTime, dispatch_get_main_queue()) {
      if(completion != nil){ completion!() }
    }
  }
}

class ViewController: UIViewController, UIWebViewDelegate {
  
  @IBOutlet weak var webView: UIWebView!
  var bridge:WebViewJavascriptBridge!
  var imagesArray:[String]!
  var photos:[NSURL] = []
  var tapedImageView: UIImageView!
  var loadingView: UIActivityIndicatorView!
  var bottomView:UIView!
  var bottomViewHasAdd = false
  var articleId:Int!
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    tapedImageView = UIImageView()
    view.addSubview(self.tapedImageView)
    loadingView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    loadingView.center = view.center
    webView.scrollView.delegate = self
    webView.backgroundColor = UIColor.whiteColor()
    
    bridge = WebViewJavascriptBridge(forWebView: webView, webViewDelegate: self, handler: { [weak self](data, responseCallBack) -> Void in
      self?.imagesArray = data as! [String]
      self?.downloadAllImagesInNative(self!.imagesArray)
      })
    
    bridge.registerHandler("imageDidClicked") { [weak self](data, responseCallback) -> Void in
      let index = data.objectForKey("index")?.integerValue
      
      let originX = data.objectForKey("x")!.floatValue
      let originY = data.objectForKey("y")!.floatValue + 64
      let width = data.objectForKey("width")!.floatValue
      let height = data.objectForKey("height")!.floatValue
      
      self?.tapedImageView.alpha = 0
      self?.tapedImageView.frame = CGRect(x: CGFloat(originX), y: CGFloat(originY), width: CGFloat(width), height: CGFloat(height))
      self?.tapedImageView.sd_setImageWithURL(NSURL(string: self!.imagesArray[index!]), completed: { (_ ,_ , _, _) -> Void in
        self?.presentPhotosBrowserWithInitialPage(index!, animatedFromView: self!.tapedImageView)
      })
    }
    
    requestBodyForWebView(articleId)
  }
  
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    LastWebViewOffset.offset = webView.scrollView.contentOffset.y
  }
  
  // MARK: - action
  
  func requestBodyForWebView(id: Int){
    let requst = NSURLRequest(URL: NSURL(string: "http://app.idaxiang.org/api/v1_0/art/info?id=\(id)")!)
    
    let task = NSURLSession.sharedSession().dataTaskWithRequest(requst) { [weak self](data, response, error) -> Void in
      let json = JSON(data: data!)
      
      let body = json["body"]["article"]["content"].stringValue
      var replaceBody = body.stringByReplacingOccurrencesOfString("src", withString: "esrc")
      
      let range = NSRange(location: 0, length: replaceBody.characters.count)
      let regex = try! NSRegularExpression(pattern: "(<img[^>]+esrc=\")(\\S+)\"", options: NSRegularExpressionOptions(rawValue:0))
      
      replaceBody = regex.stringByReplacingMatchesInString(replaceBody, options: NSMatchingOptions(rawValue: 0), range: range, withTemplate: "<img esrc=\"$2\" onClick=\"javascript:onImageClick('$2')\"")
      
      let htmlPath = NSBundle.mainBundle().pathForResource("news", ofType: "html")
      do {
        let defaultHtml = try NSString(contentsOfFile: htmlPath!, encoding: NSUTF8StringEncoding)
        let finalHtml = defaultHtml.stringByReplacingOccurrencesOfString("replace_body", withString: replaceBody).stringByReplacingOccurrencesOfString("h5", withString: "h1")
        let baseURL = NSURL(fileURLWithPath: htmlPath!)
        self?.webView.loadHTMLString(finalHtml, baseURL: baseURL)
        
      }catch{}
    }
    task.resume()
  }
  
  func downloadAllImagesInNative(imageUrls: [String]) {
    let mannager = SDWebImageManager.sharedManager()
    for imageUrlString in imageUrls {
      mannager.downloadImageWithURL(NSURL(string: imageUrlString)!, options: .HighPriority, progress: nil, completed: {[weak self] (image, error, cacheType, finished, imageUrl) -> Void in
        backgroundThread(0, background: { () -> Void in
          let imgB64 = UIImageJPEGRepresentation(image, 1.0)?.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
          self?.photos.append(imageUrl)
          let key = mannager.cacheKeyForURL(imageUrl)
          let source = "data:image/png;base64,\(imgB64!)"
          self?.bridge.callHandler("imagesDownloadComplete", data: [key,source])
          }, completion: nil)
        
        })
    }
  }
  
  func presentPhotosBrowserWithInitialPage(index:Int, animatedFromView: UIImageView) {
    let browser = IDMPhotoBrowser(photoURLs: imagesArray, animatedFromView: animatedFromView)
    browser.scaleImage = animatedFromView.image
    browser.setInitialPageIndex(UInt(index))
    presentViewController(browser, animated: true) { () -> Void in
      
    }
  }
  
  deinit{
    print("销毁 详细页面")
  }
}

extension ViewController {
  func webViewDidStartLoad(webView: UIWebView) {
    view.insertSubview(loadingView, aboveSubview: webView)
    loadingView.startAnimating()
  }
  func webViewDidFinishLoad(webView: UIWebView) {
//    if LastWebViewOffset.offset != 0 {
//      webView.scrollView.contentOffset = CGPoint(x: 0, y: LastWebViewOffset.offset)
//    }
    loadingView.stopAnimating()
    loadingView.removeFromSuperview()
    
  }
}


extension ViewController: UIScrollViewDelegate {
  func scrollViewDidScroll(scrollView: UIScrollView) {
    if  scrollView.contentOffset.y > webView.scrollView.contentSize.height - view.frame.height*2 {
      if !bottomViewHasAdd {
        let offsetY = webView.scrollView.contentSize.height
        bottomView = UIView()
        
        bottomView.frame = CGRect(x: 0, y: offsetY, width: view.frame.width, height: 120)
        let label = UILabel()
        label.text = "这是个add 在webView 的 普通viewO ~"
        label.sizeToFit()
        
        bottomView.backgroundColor = UIColor.yellowColor()
        webView.scrollView.addSubview(bottomView)
        bottomView.addSubview(label)
        label.center = bottomView.center
        webView.scrollView.contentSize.height += 120
        let tapGesture = UITapGestureRecognizer(target: self , action: "tapMe")
        webView.addGestureRecognizer(tapGesture)
      }
      bottomViewHasAdd = true
    }
  }
  
  func tapMe(){
    print("tap bottom view.")
  }
}
