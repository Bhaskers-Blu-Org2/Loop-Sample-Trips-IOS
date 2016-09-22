//
//  TripViewController.swift
//  Trips App
//
//  Copyright (c) Microsoft Corporation
//
//  All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the License); you may not 
//  use this file except in compliance with the License. You may obtain a copy 
//  of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  THIS CODE IS PROVIDED ON AN *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS 
//  OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY 
//  IMPLIED WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE, 
//  MERCHANTABLITY OR NON-INFRINGEMENT.
//
//  See the Apache Version 2.0 License for specific language governing permissions 
//  and limitations under the License.
//

import Foundation
import UIKit
import CoreLocation
import LoopSDK

class TripViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tripTableView: UITableView!

    private var repositoryManagerUpdateObserver: NSObjectProtocol!
    
    let cellViewHeight: CGFloat = 94.0
    let repositoryManager = RepositoryManager.sharedInstance
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(TripViewController.onPullToRefresh(refreshControl:)), for: .valueChanged)
        return refreshControl
    }()
    
    override func viewDidAppear(_ animated: Bool) {
        if (LoopSDK.isInitialized()) {
            if (!LoopSDK.loopLocationProvider.active || LoopSDK.loopLocationProvider.listenerStatus != CLAuthorizationStatus.authorizedAlways) {
                AlertUtils.AlertWithCallback(uiView: self, title: "Trip Recording Off".localized,
                                                            message: "TURN_ON_TRIP_RECORDING_MESSAGE".localized,
                                                            confirmButtonText: "Go to Settings".localized,
                                                            callback: {
                    self.tabBarController?.selectedIndex = 1
                })
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let repositoryManagerUpdateObserver = repositoryManagerUpdateObserver {
            NotificationCenter.default.removeObserver(repositoryManagerUpdateObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        repositoryManagerUpdateObserver = NotificationCenter.default
            .addObserver(forName: NSNotification.Name(rawValue: RepositoryManagerAddedContentNotification),
                                object: nil,
                                queue: OperationQueue.main) {
                                    notification in
                                    self.contentChangedNotification(notification: notification as NSNotification!)
        }
        
        self.tripTableView.register(UINib(nibName: "TripCell", bundle: nil), forCellReuseIdentifier: "TripCell")

        self.repositoryManager.loadRepositoryDataAsync(sendUpdateNotification: true)
        
        self.tripTableView.addSubview(self.refreshControl)
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.tripTableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMapViewForTrips", let mapView = segue.destination as? MapViewController {
            if let indexPath = sender as? NSIndexPath {
                let row = self.repositoryManager.tripRepository.tableData[indexPath.row]
                mapView.setData(tripData: row.data!, isSample: row.isSample)
            }
        }
    }
}


// MARK - Privates

extension TripViewController {
    open func onPullToRefresh(refreshControl: UIRefreshControl) {
        self.repositoryManager.loadRepositoryDataAsync(sendUpdateNotification: false)
        
        DispatchQueue.main.async {
            self.tripTableView.reloadData()
            refreshControl.endRefreshing()
        }
    }
    
    fileprivate func contentChangedNotification(notification: NSNotification!) {
        switch notification.name.rawValue {
        case RepositoryManagerAddedContentNotification:
            NSLog("Received update notification in TripView")
            self.tripTableView.reloadData()
        default:
            NSLog("Unknown notification")
        }
    }
}


// MARK - UITableViewDataSource

extension TripViewController {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.repositoryManager.tripRepository.tableData.count
    }
    
    @objc(tableView:cellForRowAtIndexPath:) public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TripCell", for: indexPath as IndexPath) as! TripCell
        let row = self.repositoryManager.tripRepository.tableData[indexPath.row]
        cell.setData(trip: row.data!, isSample: row.isSample)
        
        return cell
    }

    // Not handling this right now
    /*
    @objc(tableView:canEditRowAtIndexPath:) public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    */
}

// MARK - UITableViewDelegate
extension TripViewController {
    @objc(tableView:heightForRowAtIndexPath:) public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (self.repositoryManager.tripRepository.tableData[indexPath.row].isSample) {
            return cellViewHeight
        }
        else {
            return cellViewHeight - 24.0
        }
    }
    
    @objc(tableView:didSelectRowAtIndexPath:) public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showMapViewForTrips", sender: indexPath)
    }
    
    // Not handling this right now
    /*
    // supercedes -tableView:titleForDeleteConfirmationButtonForRowAtIndexPath: if return value is non-nil
    @objc(tableView:editActionsForRowAtIndexPath:) public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: {
            (action, indexPath) in

            self.repositoryManager.tripRepository.removeData(index: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        })

        deleteAction.backgroundColor = UIColor.tableCellDeleteActionColor

        return [deleteAction]
    }
    */
}
