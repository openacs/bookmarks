ad_page_contract {
    Entry page for the bookmarks module

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
    viewed_user_id:integer,optional
    {sort_by "name"}

} -validate {
    valid_user_id -requires {viewed_user_id:integerl} {
	if { [empty_string_p [db_string user_exists "select 1 from parties where party_id = :viewed_user_id" -bind "viewed_user_id $viewed_user_id" -default ""]] } {
	    ad_complain "The user_id in the url is invalid"
	}
    }

} -properties {
    page_title:onevalue
    context:onevalue
    bookmark:multirow
    browsing_user_id:onevalue
    viewed_user_id:onevalue
    root_admin_p:onevalue
    bookmarks_admin_p:onevalue
    write_p:onevalue
    sort_by:onevalue
    user_name:onevalue
    this_url_urlenc:onevalue
    return_url_urlenc:onevalue
}

set browsing_user_id [ad_conn user_id]

# Is the user viewing his own bookmarks?
if { ![info exists viewed_user_id] || [string equal $viewed_user_id $browsing_user_id] } {
    # The user is viewing his own bookmarks
    set viewed_user_id $browsing_user_id
    set context {}
}

set this_url_urlenc [ad_urlencode [ad_conn url]]


# To enable non-registered users to view registered users bookmarks (if they have
# permission) we use the session_id of these users as the id in the bm_in_closed_p
# table
set in_closed_p_id [ad_decode $browsing_user_id "0" [ad_conn session_id] $browsing_user_id]


# In case this is the first time the user views this bookmark tree
# we need to populate the table keeping track of which bookmarks are in
# closed folders
bm_initialize_in_closed_p $viewed_user_id $in_closed_p_id

# When we are adding a bookmark we need to know which url to return to
# A bookmark can also be added via a Bookmarklet in which case return url
# will be the page that the user is browsing.
set return_url_urlenc [ad_urlencode [ad_conn url]?[export_url_vars viewed_user_id]]

set user_name [db_string user_name "select first_names || ' ' || last_name from cc_users where object_id = :viewed_user_id" -bind "viewed_user_id $viewed_user_id" -default ""]

set package_id [ad_conn package_id]
if { ![string equal $viewed_user_id "0"] } {
    set root_folder_id [bm_get_root_folder_id [ad_conn package_id] $viewed_user_id]
} else {
    set root_folder_id 0
}

set root_admin_p [ad_permission_p $root_folder_id admin]
set bookmarks_admin_p [ad_permission_p $package_id admin]
set write_p [bm_user_can_write_in_some_folder_p $viewed_user_id]
set tree_url [export_vars -base tree { viewed_user_id write_p user_name }]

set permissions_url [export_vars -base bookmark-permissions { viewed_user_id user_name }]