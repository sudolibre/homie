

import UIKit
import SwiftOverlays
import PlaygroundSupport

class MyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableView: UITableView!
    let items = ["Hello 1", "Hello 2", "Hello 3"]
    
    override func viewDidAppear(_ animated: Bool) {
        print("view did apper here!")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
        self.tableView = UITableView(frame:self.view.frame)
        self.tableView!.dataSource = self
        self.tableView!.delegate = self
        self.tableView!.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(self.tableView)
        expensiveMethod()
    }
    
    // DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        return self.items.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = "\(self.items[indexPath.row])"
        return cell
    }
    
    func expensiveMethod() {
        self.perform(#selector(expIsDone), with: nil, afterDelay: 2.0)
        print("next linein exp method")
        }
        
    func expIsDone() -> String {
        let string = "Expensive method complete"
        print(string)
        return string
    }
}
var ctrl = MyViewController()
PlaygroundPage.current.liveView = ctrl.view
 
