ad_page_contract {
    Page that lets a user add a single bookmark or
    import a whole set of bookmarks from netscape.

    This script in conjunction with a bookmarklet (a bookmark
    containing a line of JavaScript) is also supposed to enable
    the user to add a bookmark to this system when he is 
    browsing the web by simply pressing a button in his browser.
    After the bookmark gets inserted the script bookmark-add-one-2
    will redirect back to the page that the user 
    was viewing. 

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
    return_url
    {viewed_user_id:integer ""}
    {local_title ""}
    {complete_url ""}

} -properties {

    page_title:onevalue
    context:onevalue
    return_url:onevalue
    viewed_user_id:onevalue
    bookmark_id:onevalue
    bookmarklet:onevalue
    local_title:onevalue
    complete_url:onevalue
    this_url_urlenc
}


# If we we are coming from a Bookmarklet there will be no viewed_user_id
# supplied, but the browsing_user_id will do
if { [empty_string_p $viewed_user_id] || $viewed_user_id == 0 } {
    set viewed_user_id [ad_conn user_id]
}

set page_title "Add/Import Bookmarks"

set context [bm_context_bar_args "\"$page_title\"" $viewed_user_id]

# get the next bookmark_id (used as primary key in bm_bookmarks)
set bookmark_id [db_nextval acs_object_id_seq]

# If the user opts to create a new folder we need to provide this url
# along with the whole url vars string to enable the user to come back
# (also needed if the user needs to log in to the system first)
set this_url_urlenc [ad_urlencode "[ad_conn url]?[export_url_vars viewed_user_id complete_url local_title return_url bookmark_id]"]

# Redirect the user to log in if he has not done so
set user_id [ad_conn user_id]
if { $user_id == "0" } {
    ad_returnredirect "/register/?return_url=$this_url_urlenc"
    ad_script_abort
}

set full_bookmark_add_url "[ad_parameter -package_id [ad_acs_kernel_id] SystemURL][ad_conn package_url]bookmark-add-import"

set bookmarklet "javascript:location.href='${full_bookmark_add_url}?return_url='+escape(location.href)+'&local_title='+escape(document.title)+'&complete_url='+escape(location.href)"

ad_return_template
