; this file is auto-generated
If Not IsMap($MM_LNG_CACHE) Then $MM_LNG_CACHE = MapEmpty()
If Not MapExists($MM_LNG_CACHE, "lang") Or Not IsMap($MM_LNG_CACHE["lang"]) Then $MM_LNG_CACHE["lang"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["lang"], "code") Or Not IsString($MM_LNG_CACHE["lang"]["code"]) Then $MM_LNG_CACHE["lang"]["code"] = "en_US"
If Not MapExists($MM_LNG_CACHE["lang"], "name") Or Not IsString($MM_LNG_CACHE["lang"]["name"]) Then $MM_LNG_CACHE["lang"]["name"] = "English"
If Not MapExists($MM_LNG_CACHE["lang"], "author") Or Not IsString($MM_LNG_CACHE["lang"]["author"]) Then $MM_LNG_CACHE["lang"]["author"] = "Aliaksei SyDr Karalenka"
If Not MapExists($MM_LNG_CACHE["lang"], "language") Or Not IsString($MM_LNG_CACHE["lang"]["language"]) Then $MM_LNG_CACHE["lang"]["language"] = "Language"
If Not MapExists($MM_LNG_CACHE, "mod_list") Or Not IsMap($MM_LNG_CACHE["mod_list"]) Then $MM_LNG_CACHE["mod_list"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["mod_list"], "mod") Or Not IsString($MM_LNG_CACHE["mod_list"]["mod"]) Then $MM_LNG_CACHE["mod_list"]["mod"] = "Mod"
If Not MapExists($MM_LNG_CACHE["mod_list"], "caption") Or Not IsString($MM_LNG_CACHE["mod_list"]["caption"]) Then $MM_LNG_CACHE["mod_list"]["caption"] = "Mod list (%s)"
If Not MapExists($MM_LNG_CACHE["mod_list"], "no_game_dir") Or Not IsString($MM_LNG_CACHE["mod_list"]["no_game_dir"]) Then $MM_LNG_CACHE["mod_list"]["no_game_dir"] = "no game dir - select from ""More actions"""
If Not MapExists($MM_LNG_CACHE["mod_list"], "up") Or Not IsString($MM_LNG_CACHE["mod_list"]["up"]) Then $MM_LNG_CACHE["mod_list"]["up"] = "Move up"
If Not MapExists($MM_LNG_CACHE["mod_list"], "down") Or Not IsString($MM_LNG_CACHE["mod_list"]["down"]) Then $MM_LNG_CACHE["mod_list"]["down"] = "Move down"
If Not MapExists($MM_LNG_CACHE["mod_list"], "enable") Or Not IsString($MM_LNG_CACHE["mod_list"]["enable"]) Then $MM_LNG_CACHE["mod_list"]["enable"] = "Enable"
If Not MapExists($MM_LNG_CACHE["mod_list"], "disable") Or Not IsString($MM_LNG_CACHE["mod_list"]["disable"]) Then $MM_LNG_CACHE["mod_list"]["disable"] = "Disable"
If Not MapExists($MM_LNG_CACHE["mod_list"], "missing") Or Not IsString($MM_LNG_CACHE["mod_list"]["missing"]) Then $MM_LNG_CACHE["mod_list"]["missing"] = "%s (missing mod)"
If Not MapExists($MM_LNG_CACHE["mod_list"], "remove") Or Not IsString($MM_LNG_CACHE["mod_list"]["remove"]) Then $MM_LNG_CACHE["mod_list"]["remove"] = "Remove"
If Not MapExists($MM_LNG_CACHE["mod_list"], "group") Or Not IsMap($MM_LNG_CACHE["mod_list"]["group"]) Then $MM_LNG_CACHE["mod_list"]["group"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["mod_list"]["group"], "enabled") Or Not IsString($MM_LNG_CACHE["mod_list"]["group"]["enabled"]) Then $MM_LNG_CACHE["mod_list"]["group"]["enabled"] = "Enabled"
If Not MapExists($MM_LNG_CACHE["mod_list"]["group"], "enabled_with_priority") Or Not IsString($MM_LNG_CACHE["mod_list"]["group"]["enabled_with_priority"]) Then $MM_LNG_CACHE["mod_list"]["group"]["enabled_with_priority"] = "Enabled (%+i)"
If Not MapExists($MM_LNG_CACHE["mod_list"]["group"], "disabled") Or Not IsString($MM_LNG_CACHE["mod_list"]["group"]["disabled"]) Then $MM_LNG_CACHE["mod_list"]["group"]["disabled"] = "Without category"
If Not MapExists($MM_LNG_CACHE["mod_list"]["group"], "disabled_group") Or Not IsString($MM_LNG_CACHE["mod_list"]["group"]["disabled_group"]) Then $MM_LNG_CACHE["mod_list"]["group"]["disabled_group"] = "%s"
If Not MapExists($MM_LNG_CACHE["mod_list"], "list_inaccessible") Or Not IsString($MM_LNG_CACHE["mod_list"]["list_inaccessible"]) Then $MM_LNG_CACHE["mod_list"]["list_inaccessible"] = ""
If Not MapExists($MM_LNG_CACHE["mod_list"], "more") Or Not IsString($MM_LNG_CACHE["mod_list"]["more"]) Then $MM_LNG_CACHE["mod_list"]["more"] = ""
If Not MapExists($MM_LNG_CACHE["mod_list"], "plugins") Or Not IsString($MM_LNG_CACHE["mod_list"]["plugins"]) Then $MM_LNG_CACHE["mod_list"]["plugins"] = "Plugins"
If Not MapExists($MM_LNG_CACHE["mod_list"], "homepage") Or Not IsString($MM_LNG_CACHE["mod_list"]["homepage"]) Then $MM_LNG_CACHE["mod_list"]["homepage"] = "Go to webpage"
If Not MapExists($MM_LNG_CACHE["mod_list"], "delete") Or Not IsString($MM_LNG_CACHE["mod_list"]["delete"]) Then $MM_LNG_CACHE["mod_list"]["delete"] = "Delete"
If Not MapExists($MM_LNG_CACHE["mod_list"], "delete_confirm") Or Not IsString($MM_LNG_CACHE["mod_list"]["delete_confirm"]) Then $MM_LNG_CACHE["mod_list"]["delete_confirm"] = "Do you really want to delete this mod? \n%s\n\n(The mod will be moved to recycle bin, if it's possible))"
If Not MapExists($MM_LNG_CACHE["mod_list"], "add_new") Or Not IsString($MM_LNG_CACHE["mod_list"]["add_new"]) Then $MM_LNG_CACHE["mod_list"]["add_new"] = "Add new mod(s)"
If Not MapExists($MM_LNG_CACHE["mod_list"], "compatibility") Or Not IsString($MM_LNG_CACHE["mod_list"]["compatibility"]) Then $MM_LNG_CACHE["mod_list"]["compatibility"] = "Compatibility"
If Not MapExists($MM_LNG_CACHE["mod_list"], "open_dir") Or Not IsString($MM_LNG_CACHE["mod_list"]["open_dir"]) Then $MM_LNG_CACHE["mod_list"]["open_dir"] = "Open mod directory"
If Not MapExists($MM_LNG_CACHE["mod_list"], "edit_mod") Or Not IsString($MM_LNG_CACHE["mod_list"]["edit_mod"]) Then $MM_LNG_CACHE["mod_list"]["edit_mod"] = "Edit mod data"
If Not MapExists($MM_LNG_CACHE["mod_list"], "pack_mod") Or Not IsString($MM_LNG_CACHE["mod_list"]["pack_mod"]) Then $MM_LNG_CACHE["mod_list"]["pack_mod"] = "Create self-extracting package"
If Not MapExists($MM_LNG_CACHE["mod_list"], "pack_mod_hint") Or Not IsString($MM_LNG_CACHE["mod_list"]["pack_mod_hint"]) Then $MM_LNG_CACHE["mod_list"]["pack_mod_hint"] = "Package will be created in background. You can continue to use MM or even close it. \n\nClose 7z console window to cancel package creation (you need then to delete created file). When 7z window disaapear - it safe to use created file."
If Not MapExists($MM_LNG_CACHE, "game") Or Not IsMap($MM_LNG_CACHE["game"]) Then $MM_LNG_CACHE["game"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["game"], "caption") Or Not IsString($MM_LNG_CACHE["game"]["caption"]) Then $MM_LNG_CACHE["game"]["caption"] = "Game"
If Not MapExists($MM_LNG_CACHE["game"], "launch") Or Not IsString($MM_LNG_CACHE["game"]["launch"]) Then $MM_LNG_CACHE["game"]["launch"] = "Launch (%s)"
If Not MapExists($MM_LNG_CACHE["game"], "change") Or Not IsString($MM_LNG_CACHE["game"]["change"]) Then $MM_LNG_CACHE["game"]["change"] = "Change"
If Not MapExists($MM_LNG_CACHE, "plugins_list") Or Not IsMap($MM_LNG_CACHE["plugins_list"]) Then $MM_LNG_CACHE["plugins_list"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["plugins_list"], "caption") Or Not IsString($MM_LNG_CACHE["plugins_list"]["caption"]) Then $MM_LNG_CACHE["plugins_list"]["caption"] = "Plugins (%s)"
If Not MapExists($MM_LNG_CACHE["plugins_list"], "global") Or Not IsString($MM_LNG_CACHE["plugins_list"]["global"]) Then $MM_LNG_CACHE["plugins_list"]["global"] = "Global"
If Not MapExists($MM_LNG_CACHE["plugins_list"], "before_wog") Or Not IsString($MM_LNG_CACHE["plugins_list"]["before_wog"]) Then $MM_LNG_CACHE["plugins_list"]["before_wog"] = "BeforeWoG"
If Not MapExists($MM_LNG_CACHE["plugins_list"], "after_wog") Or Not IsString($MM_LNG_CACHE["plugins_list"]["after_wog"]) Then $MM_LNG_CACHE["plugins_list"]["after_wog"] = "AfterWoG"
If Not MapExists($MM_LNG_CACHE["plugins_list"], "back") Or Not IsString($MM_LNG_CACHE["plugins_list"]["back"]) Then $MM_LNG_CACHE["plugins_list"]["back"] = "Back"
If Not MapExists($MM_LNG_CACHE["plugins_list"], "default") Or Not IsString($MM_LNG_CACHE["plugins_list"]["default"]) Then $MM_LNG_CACHE["plugins_list"]["default"] = "Default"
If Not MapExists($MM_LNG_CACHE, "info_group") Or Not IsMap($MM_LNG_CACHE["info_group"]) Then $MM_LNG_CACHE["info_group"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["info_group"], "desc") Or Not IsString($MM_LNG_CACHE["info_group"]["desc"]) Then $MM_LNG_CACHE["info_group"]["desc"] = "Descripton"
If Not MapExists($MM_LNG_CACHE["info_group"], "screens") Or Not IsMap($MM_LNG_CACHE["info_group"]["screens"]) Then $MM_LNG_CACHE["info_group"]["screens"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["info_group"]["screens"], "caption") Or Not IsString($MM_LNG_CACHE["info_group"]["screens"]["caption"]) Then $MM_LNG_CACHE["info_group"]["screens"]["caption"] = "Screenshots"
If Not MapExists($MM_LNG_CACHE["info_group"], "no_info") Or Not IsString($MM_LNG_CACHE["info_group"]["no_info"]) Then $MM_LNG_CACHE["info_group"]["no_info"] = "No description available"
If Not MapExists($MM_LNG_CACHE["info_group"], "info") Or Not IsMap($MM_LNG_CACHE["info_group"]["info"]) Then $MM_LNG_CACHE["info_group"]["info"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["info_group"]["info"], "caption") Or Not IsString($MM_LNG_CACHE["info_group"]["info"]["caption"]) Then $MM_LNG_CACHE["info_group"]["info"]["caption"] = "Information"
If Not MapExists($MM_LNG_CACHE["info_group"]["info"], "mod_caption") Or Not IsString($MM_LNG_CACHE["info_group"]["info"]["mod_caption"]) Then $MM_LNG_CACHE["info_group"]["info"]["mod_caption"] = "Mod %s (%s)"
If Not MapExists($MM_LNG_CACHE["info_group"]["info"], "mod_caption_s") Or Not IsString($MM_LNG_CACHE["info_group"]["info"]["mod_caption_s"]) Then $MM_LNG_CACHE["info_group"]["info"]["mod_caption_s"] = "Mod %s"
If Not MapExists($MM_LNG_CACHE["info_group"]["info"], "version") Or Not IsString($MM_LNG_CACHE["info_group"]["info"]["version"]) Then $MM_LNG_CACHE["info_group"]["info"]["version"] = "Version: %s"
If Not MapExists($MM_LNG_CACHE["info_group"]["info"], "author") Or Not IsString($MM_LNG_CACHE["info_group"]["info"]["author"]) Then $MM_LNG_CACHE["info_group"]["info"]["author"] = "Author(s): %s"
If Not MapExists($MM_LNG_CACHE["info_group"]["info"], "link") Or Not IsString($MM_LNG_CACHE["info_group"]["info"]["link"]) Then $MM_LNG_CACHE["info_group"]["info"]["link"] = "Visit mod <A HREF=""homepage"">homepage</A>"
If Not MapExists($MM_LNG_CACHE["info_group"]["info"], "category") Or Not IsString($MM_LNG_CACHE["info_group"]["info"]["category"]) Then $MM_LNG_CACHE["info_group"]["info"]["category"] = "Category: %s"
If Not MapExists($MM_LNG_CACHE, "compatibility") Or Not IsMap($MM_LNG_CACHE["compatibility"]) Then $MM_LNG_CACHE["compatibility"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["compatibility"], "part1") Or Not IsString($MM_LNG_CACHE["compatibility"]["part1"]) Then $MM_LNG_CACHE["compatibility"]["part1"] = "Mod %s is incompatible with following mods:"
If Not MapExists($MM_LNG_CACHE["compatibility"], "part2") Or Not IsString($MM_LNG_CACHE["compatibility"]["part2"]) Then $MM_LNG_CACHE["compatibility"]["part2"] = "Disable these mods to reduce amount of unexpected bugs :)"
If Not MapExists($MM_LNG_CACHE["compatibility"], "launch_anyway") Or Not IsString($MM_LNG_CACHE["compatibility"]["launch_anyway"]) Then $MM_LNG_CACHE["compatibility"]["launch_anyway"] = "Launch anyway?"
If Not MapExists($MM_LNG_CACHE, "add_new") Or Not IsMap($MM_LNG_CACHE["add_new"]) Then $MM_LNG_CACHE["add_new"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["add_new"], "caption") Or Not IsString($MM_LNG_CACHE["add_new"]["caption"]) Then $MM_LNG_CACHE["add_new"]["caption"] = "Mod install (%d from %d)"
If Not MapExists($MM_LNG_CACHE["add_new"], "filter") Or Not IsString($MM_LNG_CACHE["add_new"]["filter"]) Then $MM_LNG_CACHE["add_new"]["filter"] = "Era II Mods (*.exe; *.rar; *.zip; *.7z)|All (*.*)"
If Not MapExists($MM_LNG_CACHE["add_new"], "progress") Or Not IsMap($MM_LNG_CACHE["add_new"]["progress"]) Then $MM_LNG_CACHE["add_new"]["progress"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["add_new"]["progress"], "caption") Or Not IsString($MM_LNG_CACHE["add_new"]["progress"]["caption"]) Then $MM_LNG_CACHE["add_new"]["progress"]["caption"] = "Please wait... Unpacking files..."
If Not MapExists($MM_LNG_CACHE["add_new"]["progress"], "scanned") Or Not IsString($MM_LNG_CACHE["add_new"]["progress"]["scanned"]) Then $MM_LNG_CACHE["add_new"]["progress"]["scanned"] = ""
If Not MapExists($MM_LNG_CACHE["add_new"]["progress"], "found") Or Not IsString($MM_LNG_CACHE["add_new"]["progress"]["found"]) Then $MM_LNG_CACHE["add_new"]["progress"]["found"] = "Found %i"
If Not MapExists($MM_LNG_CACHE["add_new"]["progress"], "no_mods") Or Not IsString($MM_LNG_CACHE["add_new"]["progress"]["no_mods"]) Then $MM_LNG_CACHE["add_new"]["progress"]["no_mods"] = "There is no mod in the specified file. \n\nThe possible reasons are: \n1) You use an out-of-date program version. \n2) You're trying to add not supported mod file (probably not a mod at all)."
If Not MapExists($MM_LNG_CACHE["add_new"], "unpacking") Or Not IsString($MM_LNG_CACHE["add_new"]["unpacking"]) Then $MM_LNG_CACHE["add_new"]["unpacking"] = "Please wait... Unpacking files..."
If Not MapExists($MM_LNG_CACHE["add_new"], "install") Or Not IsString($MM_LNG_CACHE["add_new"]["install"]) Then $MM_LNG_CACHE["add_new"]["install"] = "Install"
If Not MapExists($MM_LNG_CACHE["add_new"], "reinstall") Or Not IsString($MM_LNG_CACHE["add_new"]["reinstall"]) Then $MM_LNG_CACHE["add_new"]["reinstall"] = "Reinstall"
If Not MapExists($MM_LNG_CACHE["add_new"], "installed") Or Not IsString($MM_LNG_CACHE["add_new"]["installed"]) Then $MM_LNG_CACHE["add_new"]["installed"] = "Please wait... Installing..."
If Not MapExists($MM_LNG_CACHE["add_new"], "dont_install") Or Not IsString($MM_LNG_CACHE["add_new"]["dont_install"]) Then $MM_LNG_CACHE["add_new"]["dont_install"] = "Don't install"
If Not MapExists($MM_LNG_CACHE["add_new"], "next_mod") Or Not IsString($MM_LNG_CACHE["add_new"]["next_mod"]) Then $MM_LNG_CACHE["add_new"]["next_mod"] = "Next mod"
If Not MapExists($MM_LNG_CACHE["add_new"], "close") Or Not IsString($MM_LNG_CACHE["add_new"]["close"]) Then $MM_LNG_CACHE["add_new"]["close"] = "Close"
If Not MapExists($MM_LNG_CACHE["add_new"], "exit") Or Not IsString($MM_LNG_CACHE["add_new"]["exit"]) Then $MM_LNG_CACHE["add_new"]["exit"] = "Exit"
If Not MapExists($MM_LNG_CACHE["add_new"], "version_installed") Or Not IsString($MM_LNG_CACHE["add_new"]["version_installed"]) Then $MM_LNG_CACHE["add_new"]["version_installed"] = "Mod is installed (version %s)"
If Not MapExists($MM_LNG_CACHE["add_new"], "install_package") Or Not IsString($MM_LNG_CACHE["add_new"]["install_package"]) Then $MM_LNG_CACHE["add_new"]["install_package"] = "Install package (version %s)"
If Not MapExists($MM_LNG_CACHE, "settings") Or Not IsMap($MM_LNG_CACHE["settings"]) Then $MM_LNG_CACHE["settings"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["settings"], "game_dir") Or Not IsMap($MM_LNG_CACHE["settings"]["game_dir"]) Then $MM_LNG_CACHE["settings"]["game_dir"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["settings"]["game_dir"], "change") Or Not IsString($MM_LNG_CACHE["settings"]["game_dir"]["change"]) Then $MM_LNG_CACHE["settings"]["game_dir"]["change"] = "Change game directory"
If Not MapExists($MM_LNG_CACHE["settings"]["game_dir"], "caption") Or Not IsString($MM_LNG_CACHE["settings"]["game_dir"]["caption"]) Then $MM_LNG_CACHE["settings"]["game_dir"]["caption"] = "Select game directory"
If Not MapExists($MM_LNG_CACHE["settings"], "game_exe") Or Not IsMap($MM_LNG_CACHE["settings"]["game_exe"]) Then $MM_LNG_CACHE["settings"]["game_exe"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["settings"]["game_exe"], "show_all") Or Not IsString($MM_LNG_CACHE["settings"]["game_exe"]["show_all"]) Then $MM_LNG_CACHE["settings"]["game_exe"]["show_all"] = "Show all"
If Not MapExists($MM_LNG_CACHE, "update") Or Not IsMap($MM_LNG_CACHE["update"]) Then $MM_LNG_CACHE["update"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["update"], "caption") Or Not IsString($MM_LNG_CACHE["update"]["caption"]) Then $MM_LNG_CACHE["update"]["caption"] = "Check for program updates"
If Not MapExists($MM_LNG_CACHE["update"], "current_version") Or Not IsString($MM_LNG_CACHE["update"]["current_version"]) Then $MM_LNG_CACHE["update"]["current_version"] = "Installed version: %s"
If Not MapExists($MM_LNG_CACHE["update"], "available_versions") Or Not IsString($MM_LNG_CACHE["update"]["available_versions"]) Then $MM_LNG_CACHE["update"]["available_versions"] = "Available to download:"
If Not MapExists($MM_LNG_CACHE["update"], "wait") Or Not IsString($MM_LNG_CACHE["update"]["wait"]) Then $MM_LNG_CACHE["update"]["wait"] = "wait..."
If Not MapExists($MM_LNG_CACHE["update"], "select_from_list") Or Not IsString($MM_LNG_CACHE["update"]["select_from_list"]) Then $MM_LNG_CACHE["update"]["select_from_list"] = "select from list..."
If Not MapExists($MM_LNG_CACHE["update"], "cancel") Or Not IsString($MM_LNG_CACHE["update"]["cancel"]) Then $MM_LNG_CACHE["update"]["cancel"] = "Cancel"
If Not MapExists($MM_LNG_CACHE["update"], "update_group") Or Not IsString($MM_LNG_CACHE["update"]["update_group"]) Then $MM_LNG_CACHE["update"]["update_group"] = "Selected update"
If Not MapExists($MM_LNG_CACHE["update"], "download_and_install") Or Not IsString($MM_LNG_CACHE["update"]["download_and_install"]) Then $MM_LNG_CACHE["update"]["download_and_install"] = "Download update and install automatically"
If Not MapExists($MM_LNG_CACHE["update"], "only_download") Or Not IsString($MM_LNG_CACHE["update"]["only_download"]) Then $MM_LNG_CACHE["update"]["only_download"] = "Only download"
If Not MapExists($MM_LNG_CACHE["update"], "change_dir") Or Not IsString($MM_LNG_CACHE["update"]["change_dir"]) Then $MM_LNG_CACHE["update"]["change_dir"] = "Change"
If Not MapExists($MM_LNG_CACHE["update"], "select_dir") Or Not IsString($MM_LNG_CACHE["update"]["select_dir"]) Then $MM_LNG_CACHE["update"]["select_dir"] = "Select directory"
If Not MapExists($MM_LNG_CACHE["update"], "start") Or Not IsString($MM_LNG_CACHE["update"]["start"]) Then $MM_LNG_CACHE["update"]["start"] = "Start"
If Not MapExists($MM_LNG_CACHE["update"], "close") Or Not IsString($MM_LNG_CACHE["update"]["close"]) Then $MM_LNG_CACHE["update"]["close"] = "Close"
If Not MapExists($MM_LNG_CACHE["update"], "cant_check") Or Not IsString($MM_LNG_CACHE["update"]["cant_check"]) Then $MM_LNG_CACHE["update"]["cant_check"] = "Can't check program update. Open link in browser?"
If Not MapExists($MM_LNG_CACHE["update"], "cant_download") Or Not IsString($MM_LNG_CACHE["update"]["cant_download"]) Then $MM_LNG_CACHE["update"]["cant_download"] = "Can't download program update. Open link in browser?"
If Not MapExists($MM_LNG_CACHE["update"], "info_invalid") Or Not IsString($MM_LNG_CACHE["update"]["info_invalid"]) Then $MM_LNG_CACHE["update"]["info_invalid"] = "invalid format..."
If Not MapExists($MM_LNG_CACHE, "mod_edit") Or Not IsMap($MM_LNG_CACHE["mod_edit"]) Then $MM_LNG_CACHE["mod_edit"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["mod_edit"], "caption") Or Not IsString($MM_LNG_CACHE["mod_edit"]["caption"]) Then $MM_LNG_CACHE["mod_edit"]["caption"] = "Mod edit"
If Not MapExists($MM_LNG_CACHE["mod_edit"], "save") Or Not IsString($MM_LNG_CACHE["mod_edit"]["save"]) Then $MM_LNG_CACHE["mod_edit"]["save"] = "Save"
If Not MapExists($MM_LNG_CACHE["mod_edit"], "cancel") Or Not IsString($MM_LNG_CACHE["mod_edit"]["cancel"]) Then $MM_LNG_CACHE["mod_edit"]["cancel"] = "Cancel"
If Not MapExists($MM_LNG_CACHE["mod_edit"], "group_caption") Or Not IsMap($MM_LNG_CACHE["mod_edit"]["group_caption"]) Then $MM_LNG_CACHE["mod_edit"]["group_caption"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_caption"], "caption") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_caption"]["caption"]) Then $MM_LNG_CACHE["mod_edit"]["group_caption"]["caption"] = "Caption and description"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_caption"], "language") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_caption"]["language"]) Then $MM_LNG_CACHE["mod_edit"]["group_caption"]["language"] = "Language:"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_caption"], "caption_label") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_caption"]["caption_label"]) Then $MM_LNG_CACHE["mod_edit"]["group_caption"]["caption_label"] = "Caption:"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_caption"], "description_file") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_caption"]["description_file"]) Then $MM_LNG_CACHE["mod_edit"]["group_caption"]["description_file"] = "Description file:"
If Not MapExists($MM_LNG_CACHE["mod_edit"], "group_other") Or Not IsMap($MM_LNG_CACHE["mod_edit"]["group_other"]) Then $MM_LNG_CACHE["mod_edit"]["group_other"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_other"], "caption") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_other"]["caption"]) Then $MM_LNG_CACHE["mod_edit"]["group_other"]["caption"] = "Other"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_other"], "mod_version") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_other"]["mod_version"]) Then $MM_LNG_CACHE["mod_edit"]["group_other"]["mod_version"] = "Mod version:"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_other"], "author") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_other"]["author"]) Then $MM_LNG_CACHE["mod_edit"]["group_other"]["author"] = "Author:"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_other"], "homepage") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_other"]["homepage"]) Then $MM_LNG_CACHE["mod_edit"]["group_other"]["homepage"] = "Homepage:"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_other"], "icon") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_other"]["icon"]) Then $MM_LNG_CACHE["mod_edit"]["group_other"]["icon"] = "Icon:"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_other"], "priority") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_other"]["priority"]) Then $MM_LNG_CACHE["mod_edit"]["group_other"]["priority"] = "Priority:"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_other"], "category") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_other"]["category"]) Then $MM_LNG_CACHE["mod_edit"]["group_other"]["category"] = "Category:"
If Not MapExists($MM_LNG_CACHE["mod_edit"], "group_compatibility") Or Not IsMap($MM_LNG_CACHE["mod_edit"]["group_compatibility"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "caption") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["caption"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["caption"] = "Compatibility"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "class") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["class"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["class"] = "Compatibility class:"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "all") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["all"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["all"] = "compatible with all mods"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "default") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["default"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["default"] = "incompatible with ""none"" mods"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "none") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["none"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["none"] = "incompatible with ""none"" and ""default"" mods"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "exclusions") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["exclusions"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["exclusions"] = "Exclusions:"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "mod") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["mod"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["mod"] = "Mod caption/id"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "compatible") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["compatible"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["compatible"] = "Compatible"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "yes") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["yes"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["yes"] = "Yes"
If Not MapExists($MM_LNG_CACHE["mod_edit"]["group_compatibility"], "no") Or Not IsString($MM_LNG_CACHE["mod_edit"]["group_compatibility"]["no"]) Then $MM_LNG_CACHE["mod_edit"]["group_compatibility"]["no"] = "No"
If Not MapExists($MM_LNG_CACHE, "category") Or Not IsMap($MM_LNG_CACHE["category"]) Then $MM_LNG_CACHE["category"] = MapEmpty()
If Not MapExists($MM_LNG_CACHE["category"], "gameplay") Or Not IsString($MM_LNG_CACHE["category"]["gameplay"]) Then $MM_LNG_CACHE["category"]["gameplay"] = "Gameplay"
If Not MapExists($MM_LNG_CACHE["category"], "graphics") Or Not IsString($MM_LNG_CACHE["category"]["graphics"]) Then $MM_LNG_CACHE["category"]["graphics"] = "Graphics"
If Not MapExists($MM_LNG_CACHE["category"], "scenarios") Or Not IsString($MM_LNG_CACHE["category"]["scenarios"]) Then $MM_LNG_CACHE["category"]["scenarios"] = "Scenarios"
If Not MapExists($MM_LNG_CACHE["category"], "cheats") Or Not IsString($MM_LNG_CACHE["category"]["cheats"]) Then $MM_LNG_CACHE["category"]["cheats"] = "Cheats"
If Not MapExists($MM_LNG_CACHE["category"], "interface") Or Not IsString($MM_LNG_CACHE["category"]["interface"]) Then $MM_LNG_CACHE["category"]["interface"] = "Interface"
If Not MapExists($MM_LNG_CACHE["category"], "towns") Or Not IsString($MM_LNG_CACHE["category"]["towns"]) Then $MM_LNG_CACHE["category"]["towns"] = "Towns"
If Not MapExists($MM_LNG_CACHE["category"], "other") Or Not IsString($MM_LNG_CACHE["category"]["other"]) Then $MM_LNG_CACHE["category"]["other"] = "Other"
If Not MapExists($MM_LNG_CACHE["category"], "platforms") Or Not IsString($MM_LNG_CACHE["category"]["platforms"]) Then $MM_LNG_CACHE["category"]["platforms"] = "Platforms"
If Not MapExists($MM_LNG_CACHE["category"], "personal mods") Or Not IsString($MM_LNG_CACHE["category"]["personal mods"]) Then $MM_LNG_CACHE["category"]["personal mods"] = "My personal mods"
If Not MapExists($MM_LNG_CACHE["category"], "utilities") Or Not IsString($MM_LNG_CACHE["category"]["utilities"]) Then $MM_LNG_CACHE["category"]["utilities"] = "Utilities"
