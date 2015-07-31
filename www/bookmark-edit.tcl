ad_page_contract {
    Lets a user rename, view and manage permissions of
    a bookmark or a bookmark folder.

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
    bookmark_id:naturalnum,notnull
    {viewed_user_id:naturalnum ""}
    {return_url "."}

} -validate {

    admin_rights -requires {bookmark_id:integer} {
	# Check that the user may administer this bookmark/folder
	set browsing_user_id [ad_conn user_id]

	set admin_p [db_string bookmark_admin_p "select 
	acs_permission.permission_p(:bookmark_id, :browsing_user_id, 'admin') from dual"]

	if { !($admin_p == "t") } {
	    ad_complain "We are sorry, but you do not have permissions to edit this bookmark"
	}
    }

} -properties {
    page_title:onevalue
    context:onevalue
    bookmark:onerow
    viewed_user_id:onevalue
    folder_p:onevalue
    old_private_p:onevalue
    public_possible_p:onevalue
    folder_bookmark:onevalue
    export_form_vars:onevalue
    return_url_urlenc:onevalue

} -return_errors error_list 

if { [info exists error_list] } {
    set n_errors [llength $error_list]
    ad_return_template "complaint"
}

if { $viewed_user_id eq "" } {
    set viewed_user_id [ad_conn user_id]
}

set folder_p [db_string folder_p "select folder_p from bm_bookmarks where bookmark_id = :bookmark_id"]

set folder_bookmark [ad_decode $folder_p "t" "folder" "bookmark"]

set page_title "Edit [ad_decode $folder_p "t" "Folder" "Bookmark"]"

set context [bm_context_bar_args [list $page_title] $viewed_user_id]

set delete_p [bm_delete_permission_p $bookmark_id]


# Get default setting for private_p
set old_private_p [bm_bookmark_private_p $bookmark_id]

# Check if private_p can be influenced for this bookmark
# If the bookmark is in a private folder then private_p can not
# be set directly for this bookmark
set security_inherit_p [db_string inheritance_p "select security_inherit_p from acs_objects where object_id = :bookmark_id"]

if { $old_private_p == "t" && $security_inherit_p == "t" } {
    set public_possible_p "f"
} else {
    set public_possible_p "t"
}


template::query bookmark_edit bookmark onerow "select local_title,
               owner_id,
               complete_url, 
               folder_p,
               parent_id, 
               bookmark_id
        from   bm_bookmarks, 
               bm_urls
        where  bookmark_id = :bookmark_id
        and    bm_bookmarks.url_id = bm_urls.url_id(+)"


set export_form_vars [export_vars -form {viewed_user_id folder_p old_private_p return_url}]

set return_url_urlenc [ad_urlencode $return_url]

ad_return_template
