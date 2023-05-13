//
//  ViewController.swift
//  Yelp Demo
//
//  Created by Bambang on 11/05/23.
//

import UIKit
import Alamofire
import AlamofireImage
import CoreLocation
import Cosmos
import SkeletonView

class BusinessListsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sbKeyword: UISearchBar!
    
    @IBOutlet weak var btnFilter: UIButton!
    @IBOutlet weak var btnSort: UIButton!
    @IBOutlet weak var btnOpenNow: UIButton!
    @IBOutlet weak var btnPrice: UIButton!
    
    @IBAction func btnFilterClicked(_ sender: UIButton) {
        isNearby = !isNearby
        if isNearby {
            getLocation()
        } else {
            self.latitude = 0
            self.longitude = 0
            refreshMainData()
        }
    }
    
    @IBAction func btnSortClicked(_ sender: UIButton) {
        initSort()
    }
    
    @IBAction func btnOpenNowClicked(_ sender: UIButton) {
        initOpenNow()
    }
    
    @IBAction func btnPriceClicked(_ sender: UIButton) {
        initPrice()
    }
    
    var isLoading: Bool = false
    
    var items: [BusinessModel] = []
    var currenPage = 1
    var totalPage = 1
    var totalCount = 0
    
    var keyword: String = ""
    var latitude = 0.0
    var longitude = 0.0
    var location = "NYC" // indonesia is not supported yet
    
    var sort = "best_match"
    var price = "1,2,3,4"
    var openNow: String = ""
    var isNearby: Bool = false // indonesia is not supported yet
    
    var isFirst: Bool = true
    
    private let myRefreshControl = UIRefreshControl()
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad...")
        
        sbKeyword.delegate = self
        self.generateSekelton()
        initRefreshControl()
        refreshMainData()
    }
    
    func getLocation(){
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            print("Location services are not enabled");
        }
    }
    
    func initSort(){
        let actionSheet = UIAlertController(title: "Sort type", message: "Please select", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Best Match", style: .default, handler: { _ in
            self.sort = "best_match"
            self.refreshMainData()
        }))
        actionSheet.addAction(UIAlertAction(title: "Rating", style: .default, handler: { _ in
            self.sort = "rating"
            self.refreshMainData()
        }))
        actionSheet.addAction(UIAlertAction(title: "Review count", style: .default, handler: { _ in
            self.sort = "review_count"
            self.refreshMainData()
        }))
        actionSheet.addAction(UIAlertAction(title: "Distance", style: .default, handler: { _ in
            self.sort = "distance"
            self.refreshMainData()
        }))
        actionSheet.popoverPresentationController?.sourceRect = btnSort.bounds
        actionSheet.popoverPresentationController?.sourceView = btnSort
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    func initOpenNow(){
        let actionSheet = UIAlertController(title: "Open Now", message: "Please select", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "All", style: .default, handler: { _ in
            self.openNow = "all"
            self.refreshMainData()
        }))
        actionSheet.addAction(UIAlertAction(title: "Yes", style: .default, handler: { _ in
            self.openNow = "true"
            self.refreshMainData()
        }))
        actionSheet.addAction(UIAlertAction(title: "No", style: .default, handler: { _ in
            self.openNow = "false"
            self.refreshMainData()
        }))
        actionSheet.popoverPresentationController?.sourceRect = btnOpenNow.bounds
        actionSheet.popoverPresentationController?.sourceView = btnOpenNow
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    func initPrice(){
        let actionSheet = UIAlertController(title: "Price", message: "Please select", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "All", style: .default, handler: { _ in
            self.price = "1,2,3,4"
            self.refreshMainData()
        }))
        actionSheet.addAction(UIAlertAction(title: "$", style: .default, handler: { _ in
            self.price = "1"
            self.refreshMainData()
        }))
        actionSheet.addAction(UIAlertAction(title: "$$", style: .default, handler: { _ in
            self.price = "2"
            self.refreshMainData()
        }))
        actionSheet.addAction(UIAlertAction(title: "$$$", style: .default, handler: { _ in
            self.price = "3"
            self.refreshMainData()
        }))
        actionSheet.addAction(UIAlertAction(title: "$$$$", style: .default, handler: { _ in
            self.price = "4"
            self.refreshMainData()
        }))
        actionSheet.popoverPresentationController?.sourceRect = btnPrice.bounds
        actionSheet.popoverPresentationController?.sourceView = btnPrice
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    func showErrorMessage(title: String, message: String) {
        items.removeAll()
        let err = BusinessModel(error_title: title, error_message: message)
    
        items.append(err)
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let k = searchBar.text {
            self.keyword = k
            refreshMainData()
        }
    }
    
    func initRefreshControl() {
        self.myRefreshControl.tintColor = UIColor.gray
        self.myRefreshControl.addTarget(self, action: #selector(self.refreshMainData), for: .valueChanged)
        
        if #available(iOS 10.0, *) {
            tableView.refreshControl = self.myRefreshControl
        } else {
            tableView.addSubview(self.myRefreshControl)
        }
    }
    
    @objc func refreshMainData() {
        self.currenPage = 1
        self.generateSekelton()
        self.getDatas()
    }
    
    func generateSekelton() {
        self.items.removeAll()
        self.tableView.reloadData()
        for _ in (1...10) {
            self.items.append(BusinessModel())
        }
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = self.items[indexPath.row]
        if(item.isError()) {
            return 500
        } else {
            return 120
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.items[indexPath.row]
        if(item.isError()) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "errorCell", for: indexPath) as! errorCell
            cell.displayContent(item: item)
            cell.tag = indexPath.row
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "tvcBusinessCell", for: indexPath) as! tvcBusinessCell
            if !item.isSkeleton {
                cell.hideAnimation()
            } else {
                cell.startAanimation()
            }
            cell.displayContent(item: item)
            cell.tag = indexPath.row
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
     func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        if (!item.isError()) {
            performSegue(withIdentifier: "listToDetail", sender: indexPath)
            let cell = tableView.cellForRow(at: indexPath)
            cell?.setSelected(false, animated: false)
        }
    }
    
     func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == self.items.count-1 {
            if(self.totalPage > self.currenPage && !self.isLoading) {
              print("Begin next page")
              self.currenPage += 1
              self.getDatas()
          }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "listToDetail") {
            let nav = segue.destination as! UINavigationController
            let svc = nav.topViewController as! BusinessDetailVC
            
            if let indexPath = sender as? IndexPath
            {
                svc.businessItem = self.items[indexPath.row]
                svc.business_id = self.items[indexPath.row].id
                svc.title = svc.businessItem.name
                
            }
        }
    }
    
    func getDatas() {
        if !isLoading {
            self.isLoading = true
            isFirst = false;
            
            ApiCall.getBusinessSearchs (query: keyword, page: currenPage, location: location, lat: latitude, lng: longitude, openNow: openNow, price: price, sort: sort, completion: {(newItems, total) in
                self.totalCount = total
                self.totalPage = Int(ceil(Double(total/20)))
                self.isLoading = false
                self.view.removeBluerLoader()
                self.myRefreshControl.endRefreshing()
                
                if(newItems!.count > 0) {
                    if self.currenPage ==  1 {
                        self.items = newItems!
                    } else {
                        self.items.append(contentsOf: newItems!)
                    }
                } else {
                    if(self.currenPage == 1) {
                        if self.isNearby {
                            self.showErrorMessage(title: "Error", message: "Nearby is not supported in indonesia")
                        } else {
                            self.showErrorMessage(title: "Error", message: "Opps, no data available")
                        }
                    }
                }
                
                self.tableView.reloadData()
            }, onerror: {error in
                self.isLoading = false
//                self.view.removeBluerLoader()
                self.myRefreshControl.endRefreshing()
                self.tableView.reloadData()
                self.showErrorMessage(title: "Error", message: error!)
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

class tvcBusinessCell: UITableViewCell {
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var ivRating: CosmosView!
    @IBOutlet weak var labelAddress: UILabel!
    @IBOutlet weak var labelPriceCategory: UILabel!
    @IBOutlet weak var labelDistance: UILabel!
    
    var cellItem: BusinessModel = BusinessModel()
    
    func displayContent(item: BusinessModel) {
        cellItem = item
        labelName.text = cellItem.name
        ivRating.rating = item.rating
        ivRating.text = "\(item.rating) (\(MyTools.getNumShortString(num: item.review_count)) reviews)"
        if(!item.image_url.isEmpty) {
            ivImage.showAnimatedSkeleton()
            Alamofire.request(item.image_url).responseImage { response in
                if let imageRes: UIImage = response.result.value {
                    let size = self.ivImage.frame.size
                    let aspectScaledToFillImage = imageRes.af_imageScaled(to: size)
                    self.ivImage.image = aspectScaledToFillImage
                    self.ivImage.hideSkeleton()
                }
            }
        }
        labelAddress.text = item.address
        labelPriceCategory.text = item.price + " - " + item.category
        labelDistance.text =  "\(MyTools.getDoubleString(num: item.distance/1000, fractionDigit: 1)) km"
    }
    
    func startAanimation() {
        ivRating.isHidden = true
        [labelName,labelAddress,labelPriceCategory,labelDistance].forEach
        { $0?.showAnimatedSkeleton() }
        ivImage.showAnimatedSkeleton()
        ivRating.showAnimatedSkeleton()
    }
    
    func hideAnimation() {
        ivRating.isHidden = false
        [labelName,labelAddress,labelPriceCategory,labelDistance].forEach
        { $0?.hideSkeleton() }
        ivImage.hideSkeleton()
        ivRating.hideSkeleton()
    }
}


class errorCell: UITableViewCell {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelMessage: UILabel!
    
    func displayContent(item: BusinessModel) {
        labelTitle.text = item.error_title
        labelMessage.text = item.error_message
    }
}

extension BusinessListsVC : CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         print("error:: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let locationSafe = locations.last {
            locationManager.stopUpdatingLocation()
            let latitude = locationSafe.coordinate.latitude
            let longitude = locationSafe.coordinate.longitude
            self.latitude = latitude
            self.longitude = longitude
            print(" Lat \(latitude) ,  lng \(longitude)")
            refreshMainData()
            
        }
        if locations.first != nil {
            print("location:: \(locations[0])")
        }

    }

}
