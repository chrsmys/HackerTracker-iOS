//
//  HTSpeakersTableViewController.swift
//  hackertracker
//
//  Created by Seth Law on 6/23/15.
//  Copyright (c) 2015 Beezle Labs. All rights reserved.
//

import UIKit
import CoreData

class HTSpeakersTableViewController: UITableViewController, UISearchBarDelegate {

    @IBOutlet weak var eventSearchBar: UISearchBar!
    
    var events:NSArray = []
    var filteredEvents:NSArray = []
    var selectedEvent:Event?
    var isFiltered:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(EventCell.self, forCellReuseIdentifier: "Events")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext!

        let fr:NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Event")
        fr.predicate = NSPredicate(format: "type = 'Official' AND who != ''", argumentArray: nil)
        fr.sortDescriptors = [NSSortDescriptor(key: "begin", ascending: true)]
        fr.returnsObjectsAsFaults = false
        self.events = try! context.fetch(fr) as NSArray
        
        self.tableView.reloadData()
        eventSearchBar.showsCancelButton = true
        eventSearchBar.delegate = self
        
    }
    
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (isFiltered) {
            return self.filteredEvents.count
        } else {
            return self.events.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Events", for: indexPath) as! EventCell
        
        var event : Event
        if (isFiltered) {
            event = self.filteredEvents.object(at: indexPath.row) as! Event
        } else {
            event = self.events.object(at: indexPath.row) as! Event
        }

        cell.bind(event: event)

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "searchDetailSegue", sender: indexPath)
    }

    // MARK: - Search Bar Functions
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isFiltered = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        let searchText = searchBar.text
        if (searchText!.characters.count == 0) {
            isFiltered = false
        } else {
            isFiltered = true
        }
        
        let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext!
        
        let fr:NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName:"Event")
        fr.sortDescriptors = [NSSortDescriptor(key: "begin", ascending: true)]
        fr.returnsObjectsAsFaults = false
        fr.predicate = NSPredicate(format: "location contains[cd] %@ OR title contains[cd] %@ OR who contains[cd] %@", argumentArray: [searchText!,searchText!,searchText!])
        self.filteredEvents = try! context.fetch(fr) as NSArray
        
        self.tableView.reloadData()
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let searchText = searchBar.text
        if (searchText!.characters.count == 0) {
            isFiltered = false
        } else {
            isFiltered = true
        }
        
        let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.managedObjectContext!
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName:"Event")
        fr.sortDescriptors = [NSSortDescriptor(key: "begin", ascending: true)]
        fr.returnsObjectsAsFaults = false
        fr.predicate = NSPredicate(format: "location contains[cd] %@ OR title contains[cd] %@ OR who contains[cd] %@", argumentArray: [searchText!,searchText!,searchText!])
        self.filteredEvents = try! context.fetch(fr) as NSArray
        
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if (searchText.characters.count == 0) {
            isFiltered = false
        } else {
            isFiltered = true
            
            let delegate : AppDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = delegate.managedObjectContext!
            
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName:"Event")
            fr.sortDescriptors = [NSSortDescriptor(key: "begin", ascending: true)]
            fr.returnsObjectsAsFaults = false
            fr.predicate = NSPredicate(format: "location contains[cd] %@ OR title contains[cd] %@ OR who contains[cd] %@", argumentArray: [searchText,searchText,searchText])
            self.filteredEvents = try! context.fetch(fr) as NSArray
            
            self.tableView.reloadData()
            
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "searchDetailSegue") {
            let dv : HTEventDetailViewController = segue.destination as! HTEventDetailViewController

            guard let indexPath = sender as? IndexPath else {
                fatalError("Failed to recieve index path during segue")
            }

            if isFiltered {
                dv.event = self.filteredEvents.object(at: indexPath.row) as? Event
            } else {
                dv.event = self.events.object(at: indexPath.row) as? Event
            }
        }
    }

}
