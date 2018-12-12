//  Copyright © 2018 IBM.

import UIKit

class HelpViewController: UIViewController {
    @IBOutlet weak var helpText: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if baseline == 0 { //i.e. baseline period is not over
            helpText.text = "You are in the baseline period."
        } else {
            if group == "Treatment1" ||  group == "Treatment0" { //Receiving random notifications
                helpText.text = "Help text here"
            } else if group == "Treatment2"  { // Receiving
                let df = DateFormatter()
                df.dateFormat = "hh:mm aa"
                helpText.text = "You will receive reminders sometime before and after at \(df.string(from: SelectedThingTime))."
            } else if group == "Control" {
                 helpText.text = "You can view your steps on the main screen"
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func doneInstructionsButton(_ sender: Any) {
        //self.dismiss(animated: true, completion: nil)
        self.performSegue(withIdentifier: "doneInstructionsSegue", sender: self)
    }
}
