//
//  ReportTableViewController.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/7.
//

import UIKit

class ReportTableViewController: UITableViewController {
    var postID: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "檢舉"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReportCell")
        tableView.tintColor = .white
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return ReportType.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.textProperties.color = .white
        let reportType = ReportType.allCases[indexPath.row]
        content.attributedText = attributedTextForm(content: "\(reportType)", size: 18, kern: 0, color: .white)
        cell.contentConfiguration = content
        cell.backgroundColor = .black
        cell.selectionStyle = .none
        cell.accessoryType = .disclosureIndicator
        return cell
    }
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        "您為何要檢舉這則貼文？"
//    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedReportType = ReportType.allCases[indexPath.row]
        let postID = postID  

        FirebaseManager.shared.addReportToPost(postID: postID, reportType: selectedReportType) { success, error in
            if success {
                print("Report updated successfully.")
                CustomFunc.customAlert(title: "謝謝您的回報", message: "我們將審查此篇貼文是否違反網路使用規範", vc: self) {
                    self.dismiss(animated: true)
                }
            } else if let error = error {
                print("Failed to update report: \(error.localizedDescription)")
                CustomFunc.customAlert(title: "網路異常", message: "請確認網路連線狀態", vc: self, actionHandler: nil)
            }
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UITableViewHeaderFooterView()
        header.textLabel?.attributedText = attributedTextForm(content: "回報貼文問題", size: 16, kern: 0, color: .white)
        header.textLabel?.frame = header.contentView.bounds
        header.contentView.backgroundColor = .black
        return header
    }

    // 設定 header 的高度
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }

}
