//
//  YKBaseTableViewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/9.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit

class YKBaseTableViewController : YKBaseViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate,UISearchControllerDelegate,UISearchResultsUpdating {
    
    lazy var tableView: UITableView =  {
        let t = UITableView(frame: CGRect.zero, style: .plain)
        t.delegate = self
        t.dataSource = self
        t.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        t.separatorStyle = .none
        return t
    }()
    
    var searchController: UISearchController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.tableView.frame = self.view.bounds
        self.setupTableView()
    }
    
    func setupTableView() {
        
    }
    
    func setupSearch() {
        let search = UISearchController(searchResultsController: nil)
        search.searchResultsUpdater = self
        search.searchBar.placeholder = YKLocalizedString("搜索库和库中的文件")
        search.searchBar.delegate = self
        search.delegate = self
        search.dimsBackgroundDuringPresentation = true
        search.hidesNavigationBarDuringPresentation = true
        self.searchController = search
        self.definesPresentationContext = true
        
        self.tableView.tableHeaderView = search.searchBar
    }
    
    func setTableFootHeight(_ height: CGFloat) {
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: height))
    }
    
    //MARK: UISearchResultsUpdating
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    //MARK: UISearchControllerDelegate
    
    
    //MARK: UISearchBarDelegate
    
    
    //MARK: UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
}
