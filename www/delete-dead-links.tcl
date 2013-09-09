ad_page_contract {
    deletes all occurrences of bookmarks with a dead url

    @param deleteable_link Contains bookmark ids to delete

    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id$
} {
    deleteable_link:integer,notnull,multiple
    {return_url:trim ""}
    {viewed_user_id:integer ""}
} -return_errors error_list

if { [info exists error_list] } {
    set n_errors [llength $error_list]
    ad_return_template "complaint"
}

set package_id [ad_conn package_id]

if { [empty_string_p $viewed_user_id] } {
    # Only admins can call this page for all users
    permission::require_permission -object_id $package_id -privilege admin
    set root_folder_id $package_id
   
} else {
    # Only check urls belonging to the viewed user
    set root_folder_id [bm_get_root_folder_id $package_id $viewed_user_id]

}

set browsing_user_id [ad_conn user_id]

# Loop throught the bookmark_ids to delete 
foreach url_id $deleteable_link {

    db_foreach bookmark_ids_for_url "select bookmark_id
    from (select bookmark_id, url_id from bm_bookmarks
                        start with parent_id = :root_folder_id 
                        connect by prior bookmark_id = parent_id) bm
    where acs_permission.permission_p(bm.bookmark_id, :browsing_user_id, 'delete') = 't'
    and bm.url_id = :url_id" {

	if [catch {db_exec_plsql delete_dead_link "
	begin
	bookmark.del (
	bookmark_id => :bookmark_id
	);       
        end;"} errmsg] {

	    set n_errors 1
	    set error_list [list "We encountered an error while trying to process this DELETE:
	    <pre>$errmsg</pre>"]
	    ad_return_template "error"
	    return
	}
    }

    if { [empty_string_p $viewed_user_id] } {
	permission::require_permission -object_id $package_id -privilege admin

	# Delete the url it self
	if [catch {db_exec_plsql delete_dead_link "
	begin
	url.del (
	url_id => :url_id
	);       
        end;"} errmsg] {

	    set n_errors 1
	    set error_list [list "We encountered an error while trying to process this DELETE:
	    <pre>$errmsg</pre>"]
	    ad_return_template "error"
	    return
	}	
    }

}

ad_returnredirect $return_url?viewed_user_id=$viewed_user_id








