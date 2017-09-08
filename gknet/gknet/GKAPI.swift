//
//  gkapis.swift
//  gknet
//
//  Created by wqc on 2017/7/28.
//  Copyright © 2017年 wqc. All rights reserved.
//

import Foundation

struct GKAPI {
    
    static let OAUTH_TOKEN          = "/oauth2/token2"
    static let SOURCE_INFO          = "/1/config/source"
    static let ACCOUNT_INFO         = "/1/account/info"
    static let ENTS                 = "/1/account/ent"
    static let MOUNTS               = "/1/account/mount"
    static let SHORTCUTS            = "/1/member/get_shortcuts"
    static let FILE_LIST            = "/1/file/ls"
    static let MOUNT_INFO           = "/library/info"
    static let FILE_SEARCH          = "/2/file/search"
    static let FILE_COPY            = "/1/file/copy"
    static let FILE_MOVE            = "/1/file/move"
    static let FILE_SAVE            = "/2/file/save"
    static let FILE_RENAME          = "/1/file/rename"
    static let FILE_DELETE          = "/1/file/del"
    static let FAVORITE_FILES       = "/1/file/favorites"
    static let CREATE_FOLDER        = "/2/file/create_folder"
    static let CREATE_FILE          = "/2/file/create_file"
    static let GET_DOWNLOAD_URL     = "/1/file/get_url_by_filehash"
    static let GET_SERVER_SITE      = "/1/account/servers"
}
