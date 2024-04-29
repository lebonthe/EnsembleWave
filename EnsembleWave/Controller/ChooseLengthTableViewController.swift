//
//  ChooseLengthTableViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/9.
//

import UIKit

class ChooseLengthTableViewController: UITableViewController {

    var style = 0
    var lengths = [5, 15, 30, 60, 180, 300, 6]
    var length = 5
    var selectedIndexPath: IndexPath?
    let pickerView = UIPickerView()
    lazy var minuteRow = pickerView.selectedRow(inComponent: 0)
    lazy var secondRow = pickerView.selectedRow(inComponent: 1)
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.dataSource = self
        tabBarController?.tabBar.isHidden = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LengthCell")
        if let index = lengths.firstIndex(of: length) {
            selectedIndexPath = IndexPath(row: index, section: 0)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "LengthChosen" {
                if let destinationVC = segue.destination as? CreateViewController {
                    destinationVC.style = style
                    destinationVC.length = length
                }
            }
        }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lengths.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LengthCell", for: indexPath)
        if indexPath.row < 3 {
            cell.textLabel?.text = "\(lengths[indexPath.row]) sec"
        } else if indexPath.row == lengths.count - 1 {
            cell.textLabel?.text = "自訂時長（最多 10 分鐘）： \(minuteRow) min \(secondRow) sec"
        } else {
            cell.textLabel?.text = "\(lengths[indexPath.row] / 60) min"
        }

        if indexPath == selectedIndexPath {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let previousIndexPath = selectedIndexPath {
            tableView.cellForRow(at: previousIndexPath)?.accessoryType = .none
        }
        if indexPath.row == lengths.count - 1 {
            pickerView.isHidden = false
        } else {
            pickerView.isHidden = true
        }
        selectedIndexPath = indexPath
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        length = lengths[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
    }
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.addSubview(pickerView)
        pickerView.isHidden = true
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pickerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pickerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pickerView.heightAnchor.constraint(equalToConstant: 150)
        ])
        return view
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        150
    }
}
extension ChooseLengthTableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        2
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 11
        } else {
            return 61
        }
        
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 0 {
            return "\(row) 分鐘"
        } else {
            return "\(row) 秒"
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        minuteRow = pickerView.selectedRow(inComponent: 0)
        secondRow = pickerView.selectedRow(inComponent: 1)
        if minuteRow == 10 {
            pickerView.reloadComponent(1)
            pickerView.selectRow(0, inComponent: 1, animated: true)
            secondRow = 0
        } else if minuteRow == 0 && secondRow <= 4 {
            pickerView.selectRow(5, inComponent: 1, animated: true)
            secondRow = 5
        }
        lengths[6] = minuteRow * 60 + secondRow
        length = lengths[6]
        tableView.reloadRows(at: [IndexPath(row: lengths.count - 1, section: 0)], with: .none)
    }
}
