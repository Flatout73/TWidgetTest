//
//  TodayViewController.swift
//  TodayExtension
//
//  Created by Леонид Лядвейкин on 19.03.2018.
//  Copyright © 2018 hse. All rights reserved.
//

import UIKit
import NotificationCenter
import CryptoCurrencyKit
import JBChartView
import SwiftyJSON

class TodayViewController: UIViewController, NCWidgetProviding, JBLineChartViewDataSource, JBLineChartViewDelegate {
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var lineChartView: JBLineChartView!
    
    var dollarNumberFormatter: NumberFormatter!
    var prefixedDollarNumberFormatter: NumberFormatter!
    
    open var stats: BitCoinStats?
    open var prices: [BitCoinPrice]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dollarNumberFormatter = NumberFormatter()
        dollarNumberFormatter.numberStyle = .currency
        dollarNumberFormatter.currencyCode = "USD"
        
        prefixedDollarNumberFormatter = NumberFormatter()
        prefixedDollarNumberFormatter.numberStyle = .currency
        prefixedDollarNumberFormatter.positivePrefix = "+"
        prefixedDollarNumberFormatter.negativePrefix = "-"
        
        lineChartView.delegate = self
        lineChartView.dataSource = self

        self.extensionContext?.widgetLargestAvailableDisplayMode = NCWidgetDisplayMode.expanded
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.async {
            self.lineChartView.reloadData(animated: true)
        }
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize){
        if (activeDisplayMode == NCWidgetDisplayMode.compact) {
            self.preferredContentSize = maxSize;
        }
        else {
            self.preferredContentSize = CGSize(width: 0, height: 300);
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchPrices {
            error in
            if error == nil {
                self.updatePriceLabel()
                self.updatePriceHistoryLineChart()
            }
        }
    }
    
    func updatePriceLabel() {
        self.label1.text = dollarNumberFormatter.string(from: NSNumber(value: prices?.last?.value ?? 0))!
    }

    
    func fetchPrices(_ completion: @escaping (_ error: Error?) -> ()) {
        self.getMarketPriceInUSDForPast30Days { prices, error in
                DispatchQueue.main.async {
                    self.prices = prices
                    completion(error)
                }
            }
    }
    
    func getMarketPriceInUSDForPast30Days(_ completion: @escaping ([BitCoinPrice]?, Error?)->Void) {
        let pricesUrl = URL(string: "https://blockchain.info/charts/market-price?timespan=30days&format=json")
        let request = URLRequest(url: pricesUrl!);
        let task = URLSession.shared.dataTask(with: request) {data, response, dataError in
            if dataError == nil {
                do {
                    let pricesDictionary = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                    let priceValues = pricesDictionary["values"] as! Array<NSDictionary>
                    var prices = [BitCoinPrice]()
                    for priceDictionary in priceValues {
                        let price = BitCoinPrice(fromJSON: JSON(priceDictionary))
                        prices.append(price)
                    }
                    completion(prices, nil)
                    
                } catch {
                    completion(nil, error)
                }
                
            } else {
                completion(nil, dataError)
            }
        }
        
        task.resume()
    }
    
    open func updatePriceHistoryLineChart() {
        if let prices = prices {
            let maxPrice = prices.max(by: { $0.value < $1.value})?.value
            lineChartView.maximumValue = CGFloat(maxPrice! * 1.02)
            DispatchQueue.main.async { [weak self] in
                self?.lineChartView.reloadData()
            }
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    
    open func numberOfLines(in lineChartView: JBLineChartView!) -> UInt {
        return 1
    }
    
    open func lineChartView(_ lineChartView: JBLineChartView!, numberOfVerticalValuesAtLineIndex lineIndex: UInt) -> UInt {
        var numberOfValues = 0
        if let prices = prices {
            numberOfValues = prices.count
        }
        
        return UInt(numberOfValues)
    }
    
    open func lineChartView(_ lineChartView: JBLineChartView!, verticalValueForHorizontalIndex horizontalIndex: UInt, atLineIndex lineIndex: UInt) -> CGFloat {
        var value: CGFloat = 0.0
        if let prices = prices {
            let price = prices[Int(horizontalIndex)]
            value = CGFloat(price.value)
        }
        
        return value
    }
    
    open func lineChartView(_ lineChartView: JBLineChartView!, widthForLineAtLineIndex lineIndex: UInt) -> CGFloat {
        return 3.0
    }
    
    open func lineChartView(_ lineChartView: JBLineChartView!, colorForLineAtLineIndex lineIndex: UInt) -> UIColor! {
        return UIColor.green
    }
    
    open func verticalSelectionWidth(for lineChartView: JBLineChartView!) -> CGFloat {
        return 1.0;
    }
    
}
