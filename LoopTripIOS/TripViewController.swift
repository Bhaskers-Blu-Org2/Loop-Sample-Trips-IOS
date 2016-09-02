//
//  TripViewController.swift
//  LoopTrip
//

import Foundation
import UIKit

class TripViewController: UIViewController {
    
    @IBOutlet weak var tripTableView: UITableView!
    
    let cellViewHeight: CGFloat = 94.0
    var tripModel = TripModel.sharedInstance
    var knownLocationsModel = KnownLocationModel.sharedInstance
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(TripViewController.onPullToRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // turn off the standard separator, we have a custom separator
        self.tripTableView.separatorColor = UIColor.clearColor()
        self.tripTableView.registerNib(UINib(nibName: "TripCell", bundle: nil), forCellReuseIdentifier: "TripCell")

        loadModelDataAsync()
        
        self.tripTableView.addSubview(self.refreshControl)
    }

    func onPullToRefresh(refreshControl: UIRefreshControl) {
        self.loadModelDataAsync()
        
        refreshControl.endRefreshing()
    }
    
    func loadModelDataAsync() {
        dispatch_async(GlobalUserInitiatedQueue) {
            self.tripModel.loadData({
                dispatch_async(GlobalMainQueue) {
                    self.tripTableView.reloadData()
                }
            })
        }
        
        dispatch_async(GlobalUserInitiatedQueue) {
            self.knownLocationsModel.loadData({
                dispatch_async(GlobalMainQueue) {
                    self.view.setNeedsDisplay()
                }
            })
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showMapViewForTrips", let mapView = segue.destinationViewController as? MapViewController {
            if let indexPath = sender as? NSIndexPath {
                mapView.setData((self.tripModel.tableData[indexPath.row].data)!, showTrips: false)
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tripModel.tableData.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (self.tripModel.tableData[indexPath.row].isSampleData) {
            return cellViewHeight
        }
        else {
            return cellViewHeight - 24.0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TripCell", forIndexPath: indexPath) as! TripCell
        let row = self.tripModel.tableData[indexPath.row]
        cell.setData(row.data!, sampleTrip: row.isSampleData)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.tripModel.tableData[indexPath.row].shouldShowMap {
            self.performSegueWithIdentifier("showMapViewForTrips", sender: indexPath)
        } else {
            self.tripTableView.deselectRowAtIndexPath(indexPath, animated:true)
        }
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "Delete", handler: {
            (action, indexPath) in
            
            self.tripModel.tableData.removeAtIndex(indexPath.row)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        })
        
        deleteAction.backgroundColor = UIColor.tableCellDeleteActionColor
        
        return [deleteAction]
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
}
