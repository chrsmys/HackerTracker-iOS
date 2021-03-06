//
//  HTUpdatesViewController.swift
//  hackertracker
//
//  Created by Seth Law on 3/30/15.
//  Copyright (c) 2015 Beezle Labs. All rights reserved.
//

import UIKit
import CoreData

class HTUpdatesViewController: UIViewController {

    @IBOutlet weak var updatesTextView: UITextView!
    
    var messages: [Message] = []
    var data = NSMutableData()
    var syncAlert = UIAlertController(title: nil, message: "Syncing...", preferredStyle: .alert)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = false

        let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext!
        
        let fr:NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Message")
        fr.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fr.returnsObjectsAsFaults = false
        self.messages = (try! context.fetch(fr)) as! [Message]
        
        let df = DateFormatter()
        df.timeZone = TimeZone(abbreviation: "PDT")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        var fullText: String = ""
        for message in messages {
            fullText = "\(fullText)\(df.string(from: message.date as Date))\n\(message.msg)\n\n"
        }
        
        updatesTextView.font = UIFont(name: "Courier New", size: 14.0)
        updatesTextView.text = fullText
        updatesTextView.textColor = UIColor.white
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updatesTextView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    func updateMessages() {
        let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext!
        
        let fr:NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Message")
        fr.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fr.returnsObjectsAsFaults = false
        self.messages = (try! context.fetch(fr)) as! [Message]
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var fullText: String = ""
        for message in messages {
            //var fullDate = df.stringFromDate(message.date)
            fullText = "\(fullText)\(df.string(from: message.date as Date))\n\(message.msg)\n\n"
        }
        
        updatesTextView.text = fullText
        updatesTextView.textColor = UIColor.white
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func syncDatabase(_ sender: AnyObject) {
        //NSLog("syncDatabase")
        
        let alert : UIAlertController = UIAlertController(title: "Connection Request", message: "Connect to defcon-api for updates?", preferredStyle: UIAlertControllerStyle.alert)
        let yesItem : UIAlertAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: {
            (action:UIAlertAction) in
            let envPlist = Bundle.main.path(forResource: "Connections", ofType: "plist")
            let envs = NSDictionary(contentsOfFile: envPlist!)!
            
            self.syncAlert.view.tintColor = UIColor.black
            let loadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50)) as UIActivityIndicatorView
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
            loadingIndicator.startAnimating();
            
            self.syncAlert.view.addSubview(loadingIndicator)
            self.present(self.syncAlert, animated: true, completion: nil)
            
            let tURL = envs.value(forKey: "URL") as! String
            //NSLog("Connecting to \(tURL)")
            let URL = Foundation.URL(string: tURL)
            
            let request = NSMutableURLRequest(url: URL!)
            request.httpMethod = "GET"
            
            var queue = OperationQueue()
            var con = NSURLConnection(request: request as URLRequest, delegate: self, startImmediately: true)
        })
        let noItem : UIAlertAction = UIAlertAction(title: "No", style: UIAlertActionStyle.default, handler: {
            (action:UIAlertAction) in
            NSLog("No")
        })
        
        alert.addAction(yesItem)
        alert.addAction(noItem)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func connection(_ con: NSURLConnection!, didReceiveData _data:Data!) {
        //NSLog("didReceiveData")
        self.data.append(_data)
    }
    
    func connectionDidFinishLoading(_ con: NSURLConnection!) {
        //NSLog("connectionDidFinishLoading")
        
        let resStr = NSString(data: self.data as Data, encoding: String.Encoding.ascii.rawValue)
        
        //NSLog("response: \(resStr)")

        let dataFromString = resStr!.data(using: String.Encoding.utf8.rawValue)
        
        self.dismiss(animated: false, completion: nil)
        updateSchedule(dataFromString!)
        
    }
    
    func connection(_ connection: NSURLConnection, didFailWithError error: NSError) {
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        
        let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext!
        
        self.dismiss(animated: false, completion: nil)
        
        let failedAlert : UIAlertController = UIAlertController(title: "Connection Failed", message: "Connection to defcon-api failed. Please attempt to sync data later.", preferredStyle: UIAlertControllerStyle.alert)
        let okItem : UIAlertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
            (action:UIAlertAction) in
                let message2 = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message
                message2.date = Date()
                let synctime = df.string(from: message2.date as Date)
                message2.msg = "Update failed."
                var err:NSError? = nil
                do {
                    try context.save()
                } catch let error as NSError {
                    err = error
                } catch {
                    fatalError()
                }
            
                if err != nil {
                    NSLog("%@",err!)
                }
                NSLog("Failed connection to defcon-api. Check network settings.")
                self.updateMessages()
            })
        failedAlert.addAction(okItem)
        self.present(failedAlert, animated: true, completion: nil)
    }
    
    func updateSchedule(_ data: Data) {
        
        let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext!
        
        let json = JSON(data: data, options: JSONSerialization.ReadingOptions.mutableLeaves, error: nil)
        //let json = JSON(data: data, options: NSJSONReadingOptions.All, error: nil)
        
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        
        let updateTime = json["updateTime"].string!
        let updateDate = json["updateDate"].string!
        NSLog("schedule updated at \(updateDate) \(updateTime)")
        
        let fr:NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Status")
        let status = ((try! context.fetch(fr)) as NSArray)[0] as! Status
        
        let syncDate = df.date(from: "\(updateDate) \(updateTime)")! as Date
        NSLog("syncDate: \(df.string(from: syncDate)), lastSync: \(df.string(from: status.lastsync))")
        
        var popUpMessage = ""
        
        if ( syncDate.compare(status.lastsync) == ComparisonResult.orderedDescending) {
            
            status.lastsync = syncDate
            
            let message2 = NSEntityDescription.insertNewObject(forEntityName: "Message", into: context) as! Message
            message2.date = syncDate
            let schedule = json["schedule"].array!
            message2.msg = "Schedule updated with \(schedule.count) events."
            
            NSLog("Total events: \(schedule.count)")
            
            var mySched : [Event] = []
            
            df.dateFormat = "yyyy-MM-dd HH:mm z"
            
            for item in schedule {
                let fre:NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Event")
                fre.predicate = NSPredicate(format: "id = %@", argumentArray: [item["id"].stringValue])
                var events = try! context.fetch(fre)
                var te: Event
                if events.count > 0 {
                    te = events[0] as! Event
                } else {
                    te = NSEntityDescription.insertNewObject(forEntityName: "Event", into: context) as! Event
                    te.id = item["id"].int32Value
                    te.starred = false
                }
                
                te.who = item["who"].string!
                var d = item["date"].string!
                var b = item["begin"].string!
                var e = item["end"].string!
                if ( d == "" ) {
                    d = "2016-08-04"
                }
                if ( b != "" ) {
                    if ( b == "24:00") {
                        b = "00:00"
                        if ( d == "2016-08-04" ) {
                            d = "2016-08-05"
                        } else if ( d == "2016-08-05" ) {
                            d = "2016-08-06"
                        } else if ( d == "2016-08-06" ) {
                            d = "2016-08-07"
                        } else if ( d == "2016-08-07" ) {
                            d = "2016-08-08"
                        }
                    }
                    te.begin = df.date(from: "\(d) \(b) PDT")!
                } else {
                    te.begin = df.date(from: "\(d) 00:00 PDT")!
                }
                if ( e != "" ) {
                    if ( e == "24:00") {
                        e = "00:00"
                        if ( d == "2016-08-04" ) {
                            d = "2016-08-05"
                        } else if ( d == "2016-08-05" ) {
                            d = "2016-08-06"
                        } else if ( d == "2016-08-06" ) {
                            d = "2016-08-07"
                        } else if ( d == "2016-08-07" ) {
                            d = "2016-08-08"
                        }
                    }
                    te.end = df.date(from: "\(d) \(e) PDT")!
                } else {
                    te.end = df.date(from: "\(d) 23:59 PDT")!
                }
                
                if (item["location"] != "") {
                    te.location = item["location"].string!
                }

                if (item["title"] != "") {
                    te.title = item["title"].string!
                }
                if item["description"] != "" {
                    te.details = item["description"].string!
                }
                //NSLog("\(te.id): \(te.title) \(item["link"])")
                if ( item["link"] != nil) {
                    te.link = item["link"].string!
                }
            
                if (item["type"] != "") {
                    te.type = item["type"].string!
                }
                
                if (item["demo"] != "") {
                    te.demo = item["demo"].boolValue
                }
                
                if (item["tool"] != "") {
                    te.tool = item["tool"].boolValue
                }
                
                if (item["exploit"] != "" ) {
                    te.exploit = item["exploit"].boolValue
                }
                mySched.append(te)
            }

            
            var err:NSError? = nil
            do {
                try context.save()
            } catch let error as NSError {
                err = error
            }
            
            if err != nil {
                NSLog("%@",err!)
            }
            
            self.updateMessages()

            NSLog("Schedule Updated")
            popUpMessage = "Schedule updated"
        } else {
            NSLog("Schedule is up to date")
            popUpMessage = "Schedule is up to date"
        }

        let updatedAlert : UIAlertController = UIAlertController(title: nil, message: popUpMessage, preferredStyle: UIAlertControllerStyle.alert)
        let okItem : UIAlertAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        updatedAlert.addAction(okItem)
        self.present(updatedAlert, animated: true, completion: nil)
        
        self.data = NSMutableData()
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
