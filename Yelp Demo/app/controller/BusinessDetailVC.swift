//
//  BusinessDetailVC.swift
//  Yelp Demo
//
//  Created by Bambang on 11/05/23.
//

import UIKit
import Alamofire
import AlamofireImage
import Cosmos
import MapKit
import CoreLocation
import SkeletonView
import ImageSlideshow

class BusinessDetailVC: UITableViewController {
    public var business_id: String = "";
    public var businessItem: BusinessModel = BusinessModel()
    var reviews: [ReviewModel] = []
    var isLoading = false
    var isLoading2 = false
    
    private let myRefreshControl = UIRefreshControl()
    
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var slideshow: ImageSlideshow!
    @IBOutlet weak var labelInfo: UILabel!
    @IBOutlet weak var labelAddress: UILabel!
    @IBOutlet weak var rating1: CosmosView!
    @IBOutlet weak var rating2: CosmosView!
    @IBOutlet weak var labelRating: UILabel!
    @IBOutlet weak var reviewTableview: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initNavBarItem()
        initRefreshControl()
        reviewTableview.delegate = self
        reviewTableview.dataSource = self
        let pageIndicator = UIPageControl()
        pageIndicator.currentPageIndicatorTintColor = UIColor.lightGray
        pageIndicator.pageIndicatorTintColor = UIColor.black
        slideshow.pageIndicator = pageIndicator
        slideshow.contentScaleMode = .scaleToFill
        
//        showAnimation()
        updateLayout()
        refreshMainData()
    }
    
    func showErrorMessage(title: String, message: String) {
        self.tableView.reloadData()
    }
    
    func updateLayout() {
        print("photo count \(businessItem.photos.count)")
        print(businessItem)
        if businessItem.photos.count > 0 {
            var inputs: [InputSource] = []
            for item in businessItem.photos {
                inputs.append(AlamofireSource(urlString: item)!)
            }
            slideshow.setImageInputs(inputs)
            ivImage.isHidden = true
        } else {
            ivImage.isHidden = false
            if(!businessItem.image_url.isEmpty) {
                ivImage.showAnimatedSkeleton()
                Alamofire.request(businessItem.image_url).responseImage { response in
                    if let imageRes: UIImage = response.result.value {
                        let size = self.ivImage.frame.size
                        let aspectScaledToFillImage = imageRes.af_imageScaled(to: size)
                        self.ivImage.image = aspectScaledToFillImage
                        self.ivImage.hideSkeleton()
                    }
                }
            }
        }
        
        rating1.rating = businessItem.rating
        rating1.text = "\(businessItem.rating) (\(MyTools.getNumShortString(num: businessItem.review_count)) reviews)"
        rating2.rating = businessItem.rating
        rating2.text = "\(businessItem.rating) out of 5.0"
        labelRating.text = "\(MyTools.getNumShortString(num: businessItem.review_count)) Reviews"
        labelInfo.text = businessItem.price + " - " + businessItem.category
        labelAddress.text = businessItem.address
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
//        self.showAnimation()
        self.getDetail()
        self.getReviews()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == reviewTableview {
            let item = self.reviews[indexPath.row]
            if(item.isError()) {
                return 300
            } else {
                return 180
            }
        } else {
            let cell = tableView.cellForRow(at: indexPath)
            print("heightForRowAt: "+(cell?.reuseIdentifier ?? ""))
            if cell?.reuseIdentifier == "cellReviews" {
                print("heightForRowAt: cellReviews")
                return CGFloat(self.reviews.count * 180)
            }
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == reviewTableview {
            let item = self.reviews[indexPath.row]
            if(item.isError()) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "detailErrorCell", for: indexPath) as! detailErrorCell
                cell.displayContent(item: item)
                cell.tag = indexPath.row
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "tvcReviewCell", for: indexPath) as! tvcReviewCell
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
        return super.tableView(tableView, cellForRowAt: indexPath)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == reviewTableview {
            return 1
        }
        return super.numberOfSections(in: tableView)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == reviewTableview {
            return self.reviews.count
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView != reviewTableview {
            let cell = tableView.cellForRow(at: indexPath)
            if (cell?.reuseIdentifier == "cellViewMaps") {
                self.openMap()
            }
        }
    }
    
    func getDetail() {
        if !isLoading {
            self.isLoading = true
            
            ApiCall.getBusinessDetail(id: business_id, completion: {(item) in
                
                self.isLoading = false
                self.myRefreshControl.endRefreshing()
                
                if item != nil {
                    self.businessItem = item!
                    self.updateLayout()
//                    self.getReviews()
                } else {
                    self.showErrorMessage(title: "Error", message: "Opps, no data available")
                }
            }, onerror: {error in
                self.isLoading = false
                self.myRefreshControl.endRefreshing()
                self.showErrorMessage(title: "Error", message: error!)
            })
        }
    }
    
    func getReviews() {
        if !isLoading2 {
            self.isLoading2 = true
            
            ApiCall.getBusinessReviews(id: business_id, page: 1, completion: {(newItems, total) in
                
                self.isLoading2 = false
                self.myRefreshControl.endRefreshing()
                
                if(newItems!.count > 0) {
                    self.reviews = newItems!
                } else {
                    self.showErrorMessage(title: "Error", message: "Opps, no data available")
                }
                
                self.reviewTableview.reloadData()
            }, onerror: {error in
                self.isLoading2 = false
                self.myRefreshControl.endRefreshing()
                self.reviewTableview.reloadData()
                self.showErrorMessage(title: "Error", message: error!)
            })
        }
    }
    
    func showAnimation() {
        [labelInfo,labelAddress].forEach {
            $0?.showAnimatedSkeleton()
        }
        ivImage.showAnimatedSkeleton()
    }
    
    func hideAnimation() {
        [labelInfo,labelAddress].forEach {
            $0?.hideSkeleton()
        }
        ivImage.hideSkeleton()
    }
    
    func initNavBarItem() {
        self.navigationItem.leftBarButtonItem =
            UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.close, target: self, action: #selector(backTapped))
    }
    
    @objc func backTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func openMap() {
        let latitude: CLLocationDegrees = businessItem.latitude
        let longitude: CLLocationDegrees = businessItem.longitude
        let regionDistance:CLLocationDistance = 10000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = businessItem.name
        mapItem.openInMaps(launchOptions: options)
    }
    
}

class tvcReviewCell: UITableViewCell {
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var ivRating: CosmosView!
    @IBOutlet weak var labelText: UILabel!
    
    var cellItem: ReviewModel = ReviewModel()
    
    func displayContent(item: ReviewModel) {
        cellItem = item
        labelName.text = cellItem.user.name
        ivRating.rating = item.rating
        ivRating.text = cellItem.time_created.timeAgoDisplay()
        if(!item.user.image_url.isEmpty) {
            ivImage.showAnimatedSkeleton()
            Alamofire.request(item.user.image_url).responseImage { response in
                if let imageRes: UIImage = response.result.value {
                    let size = self.ivImage.frame.size
                    let aspectScaledToFillImage = imageRes.af_imageScaled(to: size)
                    self.ivImage.image = aspectScaledToFillImage
                    self.ivImage.hideSkeleton()
                }
            }
        }
        labelText.text = item.text
    }
    
    func startAanimation() {
        ivRating.isHidden = true
        [labelName,labelText].forEach
        { $0?.showAnimatedSkeleton() }
        ivImage.showAnimatedSkeleton()
        ivRating.showAnimatedSkeleton()
    }
    
    func hideAnimation() {
        ivRating.isHidden = false
        [labelName,labelText].forEach
        { $0?.hideSkeleton() }
        ivImage.hideSkeleton()
        ivRating.hideSkeleton()
    }
}


class detailErrorCell: UITableViewCell {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelMessage: UILabel!
    
    func displayContent(item: ReviewModel) {
        labelTitle.text = item.error_title
        labelMessage.text = item.error_message
    }
}


