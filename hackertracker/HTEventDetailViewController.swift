//
//  HTEventDetailViewController.swift
//  hackertracker
//
//  Created by Seth Law on 4/17/15.
//  Copyright (c) 2015 Beezle Labs. All rights reserved.
//

import UIKit
import CoreData

class HTEventDetailViewController: UIViewController {

    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventNameButton: UIButton!
    @IBOutlet weak var eventDateLabel: UILabel!
    @IBOutlet weak var eventStartTimeLabel: UILabel!
    @IBOutlet weak var eventStopTimeLabel: UILabel!
    @IBOutlet weak var eventLocationLabel: UILabel!
    @IBOutlet weak var eventDetailTextView: UITextView!
    @IBOutlet weak var eventStarredButton: UIBarButtonItem!
    @IBOutlet weak var demoImage: UIImageView!
    @IBOutlet weak var exploitImage: UIImageView!
    @IBOutlet weak var toolImage: UIImageView!
    
    var event: Event?
    
    let starredButtonTitle = "REMOVE"
    let unstarredButtonTitle = "ADD"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let event = event else {
            print("HTEventDetailViewController: Event is nil")
            return
        }

        eventTitleLabel.text = event.title
        eventNameButton.setTitle(event.who, for: UIControlState())
        eventLocationLabel.text = event.location
        eventDetailTextView.text = event.details

        eventStarredButton.title = event.starred ? starredButtonTitle : unstarredButtonTitle

        toolImage.alpha = event.tool ? 1.0 : 0.1
        demoImage.alpha = event.demo ? 1.0 : 0.1
        exploitImage.alpha = event.exploit ? 1.0 : 0.1

        let eventLabel = DateFormatterUtility.dayOfWeekMonthTimeFormatter.string(from: event.begin as Date)
        let eventEnd = DateFormatterUtility.hourMinuteTimeFormatter.string(from: event.end as Date)

        eventDateLabel.text = "\(eventLabel)-\(eventEnd)"

        if let font = UIFont(name: "Courier New", size: 12.0) {
            eventStarredButton.setTitleTextAttributes([NSFontAttributeName: font], for: UIControlState())
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        eventDetailTextView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    @IBAction func toggleMySchedule(_ sender: AnyObject) {
        guard let event = event else {
            print("HTEventDetailViewController: Event is nil")
            return
        }
        
        let button = sender as! UIBarButtonItem

        if (event.starred) {
            event.starred = false
            button.title = unstarredButtonTitle
        } else {
            event.starred = true
            button.title = starredButtonTitle
        }
        self.saveContext()
    }
    
    func saveContext() {
        let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext!
        var err :NSError?
        do {
            try context.save()
        } catch let error as NSError {
            err = error
        }
        if err != nil {
            NSLog("%@",err!)
        }
    }
    
    @IBAction func closeEvent(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
