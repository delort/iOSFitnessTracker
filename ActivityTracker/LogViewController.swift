//
//  LogViewController.swift
//  ActivityTracker
//
//  Created by Stephen Schiffli on 4/25/17.
//  Copyright © 2017 MBIENTLAB Inc. All rights reserved.
//

import UIKit
import MetaWear
import MBProgressHUD

// Bar chart size and position constants
fileprivate let BarChartViewControllerBarPadding: CGFloat = 1.0
fileprivate let BarChartViewControllerNumBars = 60

// Used for Demo Mode data generation
fileprivate let BarChartViewControllerMaxBarHeight = 100
fileprivate let BarChartViewControllerMinBarHeight = 0

// Estimate of steps per mile assuming casual walking speed @150 pounds
fileprivate let StepsPerMile = 2000

class LogViewController: JBBaseChartViewController {
    @IBOutlet weak var headerView: JBChartHeaderView!
    @IBOutlet weak var barChartView: JBBarChartView!
    @IBOutlet weak var informationView: JBChartInformationView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var demoSwitch: UISwitch!
    
    var device: MBLMetaWear!
    let logFilename: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let path = paths.first {
            return "\(path)/archive_logfile"
        }
        print("Cannot find documents directory, logging not supported")
        return ""
    }()
    var logData: [LogEntry]!
    var chartData: Int!
    var timeData: Int!
    var totalCaloriesBurned: Int {
        return Int(logData.reduce(0.0) { (accum, entry) in
            return accum + entry.calories
        })
    }
    var doingReset: Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // Set up navigation bar colors
        navigationController?.navigationBar.tintColor = ColorNavigationTint
        navigationController?.navigationBar.barTintColor = ColorNavigationBarTint
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: ColorNavigationTitle,
            NSFontAttributeName: FontNavigationTitle
        ]
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        // Creating bar chart and defining its properties
        barChartView.delegate = self
        barChartView.dataSource = self
        barChartView.minimumValue = 0.0
        barChartView.isInverted = false
        barChartView.backgroundColor = ColorBarChartBackground

        // Setup title and header
        headerView.titleLabel.text = "Steps in Last Hour"
        headerView.separatorColor = ColorBarChartHeaderSeparatorColor

        // Load saved values and display
        logData = NSKeyedUnarchiver.unarchiveObject(withFile: logFilename) as? [LogEntry] ?? []
        barChartView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateInterface()
    }
    
    func updateInterface() {
        MBLMetaWearManager.shared().retrieveSavedMetaWearsAsync().success { (array) in
            if array.count > 0 {
                self.device = array.firstObject as! MBLMetaWear
                self.statusLabel.text = "Logging..."
                self.navigationItem.leftBarButtonItem?.title = "Remove"
                //refreshPressed(self)
            } else {
                self.navigationItem.leftBarButtonItem?.title = "Connect"
                self.statusLabel.text = "No MetaWear Connected"
            }
        }
    }
    
    func updateHeader() {
        headerView.subtitleLabel.text = "Active Calories burned: \(totalCaloriesBurned)"
    }
    
    @IBAction func connectionButtonPressed(_ sender: Any) {
        if navigationItem.leftBarButtonItem?.title == "Connect" {
           performSegue(withIdentifier: "ShowScanScreen", sender: nil)
        } else {
            device.connectAsync().success { (device) in
                device.setConfigurationAsync(nil)
            }
            device.forgetDevice()
            device = nil
            
            //clearLogPressed(nil)
            updateInterface()
        }
    }

    @IBAction func refreshPressed(_ sender: Any) {
        guard let device = device else {
            return
        }
        guard !demoSwitch.isOn else {
            return
        }
        statusLabel.text = "Connecting..."
        device.connectAsync().success { (device) in
            self.progressBar.isHidden = false
            self.progressBar.progress = 0.0
            self.statusLabel.text = "Syncing..."
            
            let configuration = self.device.configuration as! DeviceConfiguration
            configuration.delegate = self
            configuration.startDownload()
        }.failure { (error) in
            let alert = UIAlertController(title: "Error", message: "Cannot connect to logger, make sure it is charged and within range", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func switchChanged(_ sender: Any) {
        if demoSwitch.isOn {
            // Create some random data
            logData = []
            for i in 0..<BarChartViewControllerNumBars {
                let randOffset = Int(arc4random()) % (BarChartViewControllerMaxBarHeight - BarChartViewControllerMinBarHeight)
                let timestamp = Date(timeIntervalSinceNow: TimeInterval((BarChartViewControllerNumBars - i) * -60))
                logData.append(LogEntry(steps: BarChartViewControllerMinBarHeight + randOffset, timestamp: timestamp))
            }
        } else {
            // Reload the real data
            logData = NSKeyedUnarchiver.unarchiveObject(withFile: logFilename) as? [LogEntry] ?? []
        }
        updateHeader()
        barChartView.reloadData()
    }
    
    @IBAction func clearLogPressed(_ sender: Any) {
        try? FileManager.default.removeItem(atPath: logFilename)
        logData.removeAll()
        updateHeader()
        barChartView.reloadData()
    }
    
    @IBAction func resetDevicePressed(_ sender: Any) {
        guard let device = device else {
            return
        }
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        device.connectAsync().continueOnDispatchWithSuccess(block: { (t) -> Any? in
            return device.setConfigurationAsync(device.configuration)
        }).continueOnDispatchWithSuccess(block: { (t) -> Any? in
            return device.disconnectAsync()
        }).continueOnDispatch { (t) -> Any? in
            hud.hide(animated: true)
            if let error = t.error {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Okay", style: .default))
                self.present(alert, animated: true)
            }
            return nil
        }
    }
}

extension LogViewController: DeviceDelegate {
    func downloadDidUpdateProgress(_ number: Float) {
        progressBar.setProgress(number, animated: true)
    }
    
    func downloadDidRecieveEntry(_ entry: LogEntry) {
        logData.append(entry)
        if logData.count > BarChartViewControllerNumBars {
            logData.remove(at: 0)
        }
    }
    
    func downloadCompleteWithError(_ error: Error?) {
        if let error = error {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default))
            present(alert, animated: true)
        }
        NSKeyedArchiver.archiveRootObject(logData, toFile: logFilename)
        if !doingReset {
            updateHeader()
            barChartView.reloadData()
        } else {
            doingReset = false
            //clearLogPressed(nil)
        }
        progressBar.isHidden = true
        statusLabel.text = "Logging..."
        // We have our data so get outta here
        device.disconnectAsync()
    }
}

extension LogViewController: JBBarChartViewDataSource {
    func numberOfBars(in barChartView: JBBarChartView!) -> UInt {
        if logData.count < BarChartViewControllerNumBars {
            let emptyEntries = BarChartViewControllerNumBars - logData.count
            for _ in 0..<emptyEntries {
                logData.insert(LogEntry(), at: 0)
            }
        }
        return UInt(BarChartViewControllerNumBars)
    }
    
    func barChartView(_ barChartView: JBBarChartView!, didSelectBarAt index: UInt) {
        let entry = logData[Int(index)]
        informationView.setTitleText(entry.titleText)
        informationView.setValueText(entry.valueText, unitText: nil)
        informationView.setHidden(false, animated: true)
    }
    
    func didDeselect(_ barChartView: JBBarChartView!) {
        informationView.setHidden(true, animated: true)
    }
}

extension LogViewController: JBBarChartViewDelegate {
    func barChartView(_ barChartView: JBBarChartView!, heightForBarViewAt index: UInt) -> CGFloat {
        return CGFloat(logData[Int(index)].steps)
    }

    func barChartView(_ barChartView: JBBarChartView!, colorForBarViewAt index: UInt) -> UIColor! {
        return index % 2 == 0 ? ColorBarChartBarOrange : ColorBarChartBarRed
    }
    func barSelectionColor(for barChartView: JBBarChartView!) -> UIColor! {
        return UIColor.white
    }
    func barPadding(for barChartView: JBBarChartView!) -> CGFloat {
        return BarChartViewControllerBarPadding
    }
}
