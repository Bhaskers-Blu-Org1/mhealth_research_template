// Copyright © 2018 IBM.

import UIKit
import CoreMotion
class BaselineViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return baselinePickerData[component].count
    }
    var tempB = 0
    var tempBPicker = 1000
    var baselinePickerData: [[String]] = [[String]]()
    let pedometer = CMPedometer()
    
    //MARK: Buttons
    @IBOutlet weak var doneBaselineButton: UIButton!
    @IBOutlet weak var baselinePicker: UIPickerView!
    
    //MARK: Labels
    @IBOutlet weak var baselineStepsFromHK: UILabel!
    @IBOutlet weak var baselineCalculationLabel: UILabel!
    
    //MARK: Button actions
    @IBAction func doneBaselineButton(_ sender: Any) {
        baseline = tempB
        print("baseline: \(baseline)")
        self.performSegue(withIdentifier:"doneBaselineSegue", sender: self)
    }
    
    @IBAction func doneManualBaselineButton(_ sender: Any) {
        baseline = tempBPicker
        print("baseline: \(baseline)")
        self.performSegue(withIdentifier:"doneManualBaselineSegue", sender: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let df = DateFormatter()
        df.dateFormat = "MM-dd-yyyy hh:mm:ss a"
        let ddiff = 7
        baselineCalculationLabel.text = "Based on your past \(ddiff) days of historical data, your average daily step count is:"
        CoreMotionData.getStepCountFrom(startDate: Date() - 60*60*24*Double(ddiff)) { (sc) in
            //self.baselineCalculationLabel.text = "Based on your past  days of historical data, your average daily step count is:"
            let avg = Int(floor(Double(sc)!/Double(ddiff)))
            self.baselineStepsFromHK.text = "\(avg) steps"
            self.tempB = avg
        }
        
    }
    
    override func viewDidLoad() {
        
        //Connect data:
        self.baselinePicker.delegate = self
        self.baselinePicker.dataSource = self
        baselinePickerData = [["500","1,000","1,500","2,000"]] // actual list of SelectedThings and items to choose from
        super.viewDidLoad()
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The data to return for the row and component (column) that is being passed in
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return baselinePickerData[component][row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // This is called whenever there is a picker selection.
        tempBPicker = Int(baselinePickerData[component][row].components(separatedBy: CharacterSet.decimalDigits.inverted).joined())!
        print("\(tempBPicker)")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
