//
//  ListTableViewController.swift
//  JS_Swift
//
//  Created by mac on 15/10/28.
//  Copyright © 2015年 mac. All rights reserved.
//

import UIKit
import SwiftyJSON

struct Topic {
  
  var author:String
  var headpic:String
  var title:String
  var brief:String
  var date:NSDate
  var readCounts:Int
  var updateTime:Double
  var id:Int
  
  init(json:JSON) {
    author = json["author"].stringValue
    headpic = json["headpic"].stringValue
    title = json["title"].stringValue
    brief = json["brief"].stringValue
    readCounts = json["read_num"].intValue
    let createTimeDouble = json["create_time"].doubleValue
    let date = NSDate(timeIntervalSince1970: createTimeDouble)
    self.date = date
    updateTime = json["update_time"].doubleValue
    id = json["id"].intValue
  }
  
}

class ListTableViewController: UITableViewController {
  
  var topics =  [Topic]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    requestData()
    tableView.estimatedRowHeight = 100
  }
  
  func requestData(lastTopic:Topic? = nil){
    let request:NSURLRequest
    if lastTopic == nil {
      request = NSURLRequest(URL: NSURL(string: "http://app.idaxiang.org/api/v1_0/art/list")!)
    }else {
      let createTime = "\(lastTopic!.date.timeIntervalSince1970)"
      let updateTime = "\(lastTopic!.updateTime)"
      request = NSURLRequest(URL: NSURL(string: "http://app.idaxiang.org/api/v1_0/art/list?create_time=\(createTime)&pageSize=20&update_time=\(updateTime)")!)
    }
    let session = NSURLSession.sharedSession()
    let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
      let json = JSON(data: data!)
      let jsonArray = json["body"]["article"].array!
      for item in jsonArray {
        let topic = Topic(json: item)
        self.topics.append(topic)
      }
      dispatch_async(dispatch_get_main_queue()){
        self.tableView.reloadData()
      }
    }
    
    task.resume()
  }
  
  // MARK: - Table view data source
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return topics.count
  }
  
  
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("topicCell", forIndexPath: indexPath) as! TopicTableViewCell
    let topic = topics[indexPath.row]
    
    cell.model = topic
    
    return cell
  }
  
  // MARK: tableView delegate
  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return UITableViewAutomaticDimension
  }
  
  override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.row == topics.count - 1  {
      requestData(topics[topics.count - 1])
    }
  }
  
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    tableView.deselectRowAtIndexPath(indexPath, animated: true)
  }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "main.to.detail" {
      let cell = sender as! TopicTableViewCell
      let index = tableView.indexPathForCell(cell)
      
      let id = topics[index!.row].id
      let destinationVc = segue.destinationViewController as! ViewController
      destinationVc.articleId = id
    }
  }
}
