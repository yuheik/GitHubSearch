//
//  DetailViewController.swift
//  GitHubSearch
//
//  Created by Yuhei Kikuchi on 2018/02/05.
//  Copyright © 2018 Yuhei Kikuchi. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!


    func configureView() {
        LogUtil.traceFunc()

        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        LogUtil.traceFunc()

        // Do any additional setup after loading the view, typically from a nib.
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        LogUtil.traceFunc()

        // Dispose of any resources that can be recreated.
    }

    var detailItem: Date? {
        didSet {
            LogUtil.traceFunc()

            // Update the view.
            configureView()
        }
    }


}

