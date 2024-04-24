//
//  ChooseLengthTableViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/4/9.
//

import UIKit

class ChooseLengthTableViewController: UITableViewController {

    var style = 0
    var lengths = [5, 15, 30, 60, 180, 300, 600]
    var length = 5
    var selectedIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

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
        selectedIndexPath = indexPath
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        length = lengths[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
