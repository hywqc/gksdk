//
//  YKMountListViewController.swift
//  YunkuSDK
//
//  Created by wqc on 2017/8/8.
//  Copyright © 2017年 wqc. All rights reserved.
//

import UIKit
import gknet

class YKMountListViewController : YKBaseTableViewController,YKMountsListSectionViewDelegate {
    
    var datasource: YKMountsDataTableSource!
    var searchMaskView: YKSearchMaskViewFile?
    
    
    var displayConfig: YKFileDisplayConfig!
    
    init(datasource: YKMountsDataTableSource, config: YKFileDisplayConfig? = nil) {
        super.init(nibName: nil, bundle: nil)
        if config == nil {
            self.displayConfig = YKFileDisplayConfig()
        } else {
            self.displayConfig = config!
        }
        self.datasource = datasource
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func getTitle() -> String {
        
        if displayConfig.selectMode != .None && !displayConfig.selectTitle.isEmpty {
            return displayConfig.selectTitle
        }
        switch displayConfig.selectMode {
        case .Single,.Multi:
            if displayConfig.selectType == .Mount {
                return YKLocalizedString("选择库")
            } else {
                return YKLocalizedString("选择文件")
            }
            
        default:
            return YKLocalizedString("文件")
        }
    }
    
    var cancelSelectBarButton: UIBarButtonItem {
        return UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(onSelectCancel))
    }
    
    private func setNavButton() {
        if displayConfig.isembeed {
            return
        }
        
        if displayConfig.selectMode == .None {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "test", style: .plain, target: self, action: #selector(test))
        } else {
            switch displayConfig.selectType {
            case .Mount:
                switch displayConfig.selectMode {
                case .Multi:
                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: displayConfig.selectConfirmTitle, style: .plain, target: self, action: #selector(onSelectConfirm))
                    self.navigationItem.leftBarButtonItem = cancelSelectBarButton
                case .Single:
                    self.navigationItem.rightBarButtonItem = cancelSelectBarButton
                default:
                    break
                }
            default:
                if displayConfig.selectMode == .Single {
                    self.navigationItem.rightBarButtonItem = cancelSelectBarButton
                } else {
                    self.navigationItem.leftBarButtonItem = cancelSelectBarButton
                    onSelectChanged()
                    NotificationCenter.default.addObserver(self, selector: #selector(onSelectChanged), name: NSNotification.Name(YKBaseDisplayConfig.SelectChangeNotification), object: nil)
                }
            }
        }

        
        
    }
    
    @objc func onSelectConfirm() {
        displayConfig.selectFinishBlock?(displayConfig.selectedData,nil)
    }
    
    @objc func onSelectCancel() {
        displayConfig.selectCancelBlock?(self)
    }
    
    func onSelectChanged() {
        let barstr = displayConfig.getSelectBarStr()
        let newbar = UIBarButtonItem(title: barstr, style: .plain, target: self, action: #selector(onSelectConfirm))
        newbar.isEnabled = !displayConfig.selectedData.isEmpty
        self.navigationItem.rightBarButtonItem = newbar
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = .all
        self.automaticallyAdjustsScrollViewInsets = true
        self.title = self.getTitle()
        if displayConfig.selectMode == .None {
            self.setupSearch()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(reload), name: NSNotification.Name(rawValue: YKNotification_UpdateEnts), object: nil)
        self.setNavButton()
        
    }
    
    func test() {
//        YKSelectFileComponent.showSingleMountSelect(title: nil, cancleBlock: { (vc: UIViewController?) in
//            self.dismiss(animated: true, completion: nil)
//        }, completion: { (mount: GKMountDataItem, vc: UIViewController?) in
//            self.dismiss(animated: true, completion: nil)
//            print("selected is \(mount.org_name)")
//        }, fromVC: self)
        
//        YKSelectFileComponent.showMultiMountSelect(title: "", cancleBlock: { (vc:UIViewController?) in
//            self.dismiss(animated: true, completion: nil)
//        }, completion: { (mounts:[GKMountDataItem], vc:UIViewController?) in
//            self.dismiss(animated: true, completion: nil)
//            print("select: \(mounts.count)")
//        }, fromVC: self)
        
        YKSelectFileComponent.showMultiFileAndDirSelect(mountid: 121484, fullpath: "22", title: nil, cancleBlock: { (vc: UIViewController?) in
            self.dismiss(animated: true, completion: nil)
        }, completion: { (items:[GKFileDataItem], vc:UIViewController?) in
            self.dismiss(animated: true, completion: nil)
            print("select: \(items.count)")
        }, fromVC: self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("mount list deinit")
    }
    
    override func setupTableView() {
        self.tableView.sectionHeaderHeight = 44
        if displayConfig.selectMode == .Multi && displayConfig.selectType == .Mount {
            self.tableView.allowsMultipleSelection = true
        }
    }
    
    func reload() {
        print("reload")
        self.datasource.reload()
        self.tableView.reloadData()
    }
    
    override func setupSearch() {
        let search = UISearchController(searchResultsController: YKFileSearchResultController())
        search.searchResultsUpdater = self
        search.searchBar.placeholder = YKLocalizedString("搜索库和库中的文件")
        search.searchBar.sizeToFit()
        search.searchBar.delegate = self
        search.delegate = self
        search.dimsBackgroundDuringPresentation = false
        search.hidesNavigationBarDuringPresentation = true
        self.searchController = search
        self.definesPresentationContext = true
        
        self.tableView.tableHeaderView = search.searchBar
        
        let maskView = YKSearchMaskViewFile(frame: self.view.bounds)
        maskView.autoresizingMask = [.flexibleHeight,.flexibleWidth]
        maskView.isHidden = true
        maskView.alpha = 0
        self.view.addSubview(maskView)
        self.searchMaskView = maskView
    }
    
    //MARK: YKMountsListSectionViewDelegate
    func foldChangedWithView(_ view: YKMountsListSectionView,fold: Bool) -> Void {
        let section = view.index
        var arr = [IndexPath]()
        if fold {
            let rows = self.tableView.numberOfRows(inSection: section)
            for i in 0..<rows {
                arr.append(IndexPath(row: i, section: section))
            }
            datasource.setFoldOfSection(section, fold)
            self.tableView.deleteRows(at: arr, with: .top)
        } else {
            datasource.setFoldOfSection(section, fold)
            let rows = datasource.numberOfRowsInSection(section)
            for i in 0..<rows {
                arr.append(IndexPath(row: i, section: section))
            }
            self.tableView.insertRows(at: arr, with: .top)
        }
        
    }
    
    //MARK: UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return datasource.numberOfSections()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datasource.numberOfRowsInSection(section)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if YKAppearance.mlAllowMultiLines {
            if let item = (datasource.itemWithSection(indexPath.section, indexPath.row) as? YKMountItemCellWrap) {
                return item.rowHeight
            }
        }
        return 64
    }
    
    //MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let name = datasource.nameOfSection(section)
        let v = YKMountsListSectionView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 44), title: name.title, subtitle: name.subtitle, index: section, fold: datasource.isFoldOfSection(section), delegate: self)
        return v
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let item = datasource.itemWithSection(indexPath.section, indexPath.row)
        
        var isMount = false
        if let cellitem = item as? YKMountItemCellWrap {
            isMount = (cellitem.mountItem != nil)
        }
        
        let cellid = (isMount ? "cellmount" : "cellshortcut")
        
        var cell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: cellid)
        if cell == nil {
            cell = YKMountsListTableViewCell(style: .default, reuseIdentifier: cellid, isMount: isMount)
        }
        
        cell?.selectedBackgroundView = nil
        
        if let mountcell = cell as? YKMountsListTableViewCell {
            mountcell.bindData(item: item as? YKMountItemCellWrap)
            mountcell.sepline.isHidden = (indexPath.row == (datasource.numberOfRowsInSection(indexPath.section)-1))
        }
    
        return cell!
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        
        return indexPath
    }
    
    func showFileList(mountid: Int) {
        let controller = YKFileListViewController(mountID: mountid, fullpath: "/", config: displayConfig)
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        
        let item = datasource.itemWithSection(indexPath.section, indexPath.row)
        if let mount = item as? YKMountItemCellWrap {
            
            if mount.mountItem != nil {
                
                if displayConfig.selectMode == .None {
                    self.showFileList(mountid: mount.mountItem!.mount_id)
                } else {
                    if displayConfig.selectMode == .Single {
                        switch displayConfig.selectType {
                        case .Mount:
                            displayConfig.selectFinishBlock?([mount.mountItem!],nil)
                        default:
                            self.showFileList(mountid: mount.mountItem!.mount_id)
                        }
                        
                    } else if displayConfig.selectMode == .Multi {
                        switch displayConfig.selectType {
                        case .Mount: //多选库
                            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                            displayConfig.changeSelectData(item: mount.mountItem!, add: true, vc: self)
                            return
                        default:
                            self.showFileList(mountid: mount.mountItem!.mount_id)
                        }
                    }
                }

                
                
            } else if mount.favid != nil {
                
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        if displayConfig.selectMode == .None {
            return
        }
        
        if displayConfig.selectMode == .Multi {
            
            let item = datasource.itemWithSection(indexPath.section, indexPath.row)
            if let mount = item as? YKMountItemCellWrap {
                
                if mount.mountItem != nil {
                    switch displayConfig.selectType {
                    case .Mount:
                        tableView.deselectRow(at: indexPath, animated: true)
                        displayConfig.changeSelectData(item: mount.mountItem!, add: false, vc: self)
                    default:
                        break
                    }
                    
                }
            }
        }
        
    }

    
    //MARK: UISearchControllerDelegate
    func willPresentSearchController(_ searchController: UISearchController) {
        UIView.animate(withDuration: 0.25, animations: { 
            self.searchMaskView?.isHidden = false
            self.searchMaskView?.alpha = 1.0
        }, completion: nil)
        
        self.tabBarController?.tabBar.isHidden = true
    }
    
    func willDismissSearchController(_ searchController: UISearchController) {
        searchMaskView?.isHidden = true
        self.tabBarController?.tabBar.isHidden = false
    }
    
    
    //MARK: UISearchBarDelegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
    }
    
}
