
//  Copyright © 2018 IBM.

import UIKit

// Make sure that SelectedThingView Controller conforms to appropriate "rules" to be a data souce for the UIPickerViewClass.

class SelectedThingViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var doneSelectedThingButton: UIButton!
    @IBOutlet weak var SelectedThingNotes: UITextField!
    @IBOutlet weak var picker1: UIPickerView!
    @IBOutlet weak var picker2: UIPickerView!
    
    var SelectedThingTime : Date!
    var SelectedThing_temp : [String] = ["", ""]
    var list_of_X : [String] = [""]
    var list_of_Y : [String] = [""]
    var X_to_Y = ["" : [""]]
    
    func initializer() {
        // dummy initializers
        list_of_X = ["x1", "x2"]
        X_to_Y = ["x1":["y1","y2"], "x2":["y2","y3"]]
        list_of_Y = X_to_Y["x1"]!
        
        X_to_Y = CuesBehaviorsMapping
        list_of_X = CuesSet
        list_of_Y = CuesBehaviorsMapping[CuesSet[0]]!
        SelectedThing_temp = [list_of_X[0], ""]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        // One picker component per picker object
        return 1
        
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        // # of rows to display for each picker
        if pickerView == picker1  {
            return list_of_X.count
        }
        else {
            return list_of_Y.count
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        if pickerView == picker1 {
            return list_of_X[row]
        } else {
            return X_to_Y[SelectedThing_temp[0]]![row]
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if pickerView == picker1 {
            SelectedThing_temp[0] = list_of_X[row]
            picker2.selectRow(0, inComponent: 0, animated: true)
            set_list_of_Y(x: list_of_X[row])

            SelectedThing_temp[1] = list_of_Y[0]
            self.pickerView(picker2, numberOfRowsInComponent: list_of_Y.count)
            picker1.reloadAllComponents()
            picker2.reloadAllComponents()
        }
        else {
            picker1.reloadAllComponents()
            picker2.reloadAllComponents()
            SelectedThing_temp[1] = list_of_Y[row]
        }
    }

    func set_list_of_Y(x: String) {
        
        list_of_Y = X_to_Y[x]!
        list_of_Y = list_of_Y.filter { $0 != "" }
        print(list_of_Y)
        
    }
    
    override func viewDidLoad() {
        
        initializer()
        SelectedThingNotes.delegate = self
        self.picker1.dataSource = self
        self.picker1.delegate = self
        self.picker2.dataSource = self
        self.picker2.delegate = self
        self.doneSelectedThingButton.isEnabled = true
        self.picker1.tag = 1
        self.picker2.tag = 2
        super.viewDidLoad()
        
    }
    
    @IBAction func datePickerChanged(_ sender: Any) {
        
        let components = Calendar.current.dateComponents([.hour, .minute, .era], from: datePicker.date)
        let hour = components.hour!
        let minute = components.minute!
        SelectedThingTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!
        
    }
    
    @IBAction func doneButton(_ sender: Any) {
        
        SelectedThing = "\(SelectedThing_temp[0]) \(SelectedThing_temp[1])"
        if SelectedThing_temp[0] != "" && SelectedThing_temp[1] != "" && datePicker != nil {
            SelectedThingDetails["Notes"] = SelectedThingNotes.text ?? ""
            SelectedThingDetails["SelectedThing"]  = SelectedThing
            SelectedThingSelected = true // THIS NEEDS MORE DETAIL (e.g. make sure SelectedThing and time was chosen)
            
            self.performSegue(withIdentifier:"finishSelectedThingSegue", sender: self)
        }
    }
    
    func textFieldShouldReturn(_ scoreText: UITextField) -> Bool {
        
        self.view.endEditing(true)
        return true
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
