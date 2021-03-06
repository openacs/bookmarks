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
    viewed_user_id:naturalnum,optional
    {sort_by "name"}

} -validate {
    valid_user_id -requires {viewed_user_id:integerl} {
	if { [db_string user_exists {select 1 from parties where party_id = :viewed_user_id} \
		  -bind "viewed_user_id $viewed_user_id" \
		  -default ""] eq "" } {
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

set package_id [ad_conn package_id]

set browsing_user_id [ad_conn user_id]

# Is the user viewing his own bookmarks?
if { ![info exists viewed_user_id] || $viewed_user_id eq $browsing_user_id } {
    # The user is viewing his own bookmarks
    set viewed_user_id $browsing_user_id
    set context {}
}

set this_url_urlenc [ad_urlencode [ad_conn url]]


# To enable non-registered users to view registered users bookmarks (if they
# have permission) we use the session_id of these users as the id in the
# bm_in_closed_p table. We make the session_id negative so it doesn't collide
# with a valid user_id.
set in_closed_p_id [ad_decode $browsing_user_id "0" -[ad_conn session_id] $browsing_user_id]

# In case this is the first time the user views this bookmark tree
# we need to populate the table keeping track of which bookmarks are in
# closed folders
bm_initialize_in_closed_p $viewed_user_id $in_closed_p_id $package_id

# When we are adding a bookmark we need to know which url to return to
# A bookmark can also be added via a Bookmarklet in which case return url
# will be the page that the user is browsing.
set return_url_urlenc [ad_urlencode [export_vars -base [ad_conn url] {viewed_user_id}]]

set user_name [db_string user_name {select first_names || ' ' || last_name from cc_users where object_id = :viewed_user_id} \
		   -bind "viewed_user_id $viewed_user_id" -default ""]

set page_title [db_string bookmark_system_name {select acs_object.name(:package_id) from dual}]

set context [bm_context_bar_args "" $viewed_user_id]

if { $viewed_user_id ne "0" } {
    set root_folder_id [bm_get_root_folder_id [ad_conn package_id] $viewed_user_id]
} else {
    set root_folder_id 0
}


set root_admin_p [permission::permission_p -object_id $root_folder_id -privilege admin]
set bookmarks_admin_p [permission::permission_p -object_id $package_id -privilege admin]
set write_p [bm_user_can_write_in_some_folder_p $viewed_user_id]


# NB: KDK The one case (creation_date) was already hashed out...do not add back.
switch $sort_by {
    "name" {
	set index_order [db_map index_order_by_name ]
    }
    
    "access_date" {
	set index_order [db_map index_order_by_access_date]
    }

    #"creation_date" {
	#set index_order "/*+INDEX_DESC(bm_bookmarks bm_bookmarks_creation_date_idx)*/"
    #}

    default {
	set index_order ""
    }
}

# We let the owner of the bookmarks see which bookmarks are private,
# and use a MUCH less expensive query that doesn't hit permissions
if {$browsing_user_id eq $viewed_user_id} {
    set private_select [db_map private_select]
db_multirow bookmark my_bookmarks_select ""

} else {
    set private_select ", 'f' as private_p"
    db_multirow bookmark bookmarks_select {}
}

set tree_url [export_vars -base tree { viewed_user_id write_p user_name }]

set permissions_url [export_vars -base bookmark-permissions { viewed_user_id user_name }]

ad_return_template





