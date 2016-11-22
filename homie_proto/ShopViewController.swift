//
//  SecondViewController.swift
//  homie_proto
//
//  Created by Jonathon Day on 11/4/16.
//  Copyright © 2016 dayj. All rights reserved.
//

import UIKit

class ShopViewController: UIViewController {
    @IBAction func buttonTapped(_ sender: UIButton) {
        let url = URL(string: "https://www.amazon.com/Metal-Ball-bearing-Keyboard-Slide/dp/B000KQ5E82/ref=redir_mobile_desktop?ie=UTF8&aid=aw_gw&apid=1678137742&arc=1201&arid=31AN010BFMAM8NC4X55H&asn=center-6&ref_=s9_simh_awgw_p60_d0_i0")
        UIApplication.shared.openURL(url!)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

