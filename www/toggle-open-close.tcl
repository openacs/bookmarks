ad_page_contract {
    This script will toggle the openness of folders. The parameter action
    is provided to indicate open/close when all folders are to be opened/closed.
    In case only one folder is to be open/closed the bookmark_id of that folder
    should be provided. Note that we need the browsing_user_id to enable multiple
    users to concurrently open close the same folders without disturbing eachother.

    @param bookmark_id If bookmark_id is provided, then the folder with that id
    is toggled.
    
    @param action Allowed values are close_all and open_all. If this
    parameter is provided then all folders of the user will be toggled.
    
    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id:
} {
    {bookmark_id:integer ""}
    {action ""}
    viewed_user_id:integer
    sort_by
}

set browsing_user_id [ad_conn user_id]

if { ![empty_string_p $bookmark_id] } {
    # Toggle one folder

    db_exec_plsql toggle_open_close "
    begin
   bookmark.toggle_open_close(
   bookmark_id => :bookmark_id,
   browsing_user_id => :browsing_user_id
    );
    end;"
} elseif { [string equal $action "open_all"] || [string equal $action "close_all"] } {
    # Toggle all folders

    set closed_p [ad_decode $action "open_all" "f" "t"]
    set package_id [ad_conn package_id]
    
    db_exec_plsql toggle_open_close_all "
    begin
   bookmark.toggle_open_close_all(
   browsing_user_id => :browsing_user_id,
   closed_p => :closed_p,
   root_id => bookmark.get_root_folder(
                package_id => :package_id,
                user_id    => :viewed_user_id
              )
    );
    end;"

} else {
    # Application error
    # Either bookmark_id or action must be provided

    set n_errors 1
    set error_list [list "Missing form variables. Exactly one of bookmark_id and action
    must be provided"]
    ad_return_template "error"
    return
}


ad_returnredirect "index?viewed_user_id=$viewed_user_id&sort_by=$sort_by"












