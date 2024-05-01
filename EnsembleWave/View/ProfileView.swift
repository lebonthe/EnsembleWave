//
//  ProfileView.swift
//  EnsembleWave
//
//  Created by Min Hu on 2024/5/2.
//

import UIKit

class ProfileView: UIView {
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var likesCountLabel: UILabel!
    @IBOutlet var ensembleCountLabel: UILabel!
    @IBOutlet var userImageView: UIImageView!
    @IBOutlet var instrumentImageView: UIImageView!
    @IBOutlet var aboutMeLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        configureImageView()
        setupTableView()
    }
    private func commonInit() {
        
        if let view = Bundle.main.loadNibNamed("ProfileView", owner: self, options: nil)?.first as? UIView {
            view.frame = self.bounds
            addSubview(view)
            
        }
    }
    private func configureImageView() {
        userImageView.layer.cornerRadius = userImageView.frame.height / 2
        userImageView.clipsToBounds = true
    }
    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
}
extension ProfileView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = " \(indexPath.row) 行"
        return cell
    }
}

extension ProfileView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("選中了行：\(indexPath.row)")
    }
}
