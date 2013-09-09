ad_page_contract {
    This is the target script of the add bookmark form
    on the bookmark-add-import page. Validates the url
    that the user typed in. If no title was provided by the
    user a title will be fetched from the page to be bookmarked
    - in this case the user will be asked for a confirmation.
    
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
    {viewed_user_id:integer ""}
    {complete_url:trim ""}
    {local_title ""}
    return_url
    {bookmark_id:integer ""}
    parent_id:integer

} -validate {

    valid_url {

	# If we are coming to this page through a bookmarklet the
	# complete url will not be provided but the url to bookmark
	# is in this case the return_url which is the page that the
	# user is viewing
	if { [empty_string_p $complete_url] } {
	    set complete_url $return_url
	}

	# see if 'complete_url' is missing the protocol (ie https:// ) - 
	# if so set complete_url "http://$complete_url"
	if { ![regexp {^[^:\"]+://} $complete_url] } {
	    set complete_url "http://$complete_url"
	}

	set url_content ""
	if {[catch {ns_httpget $complete_url 10} url_content]} {
	    set url_unreachable_p "t"
	} else {
	    set url_unreachable_p "f"
	}
    }

    can_find_title {

	set url_title [bm_get_html_title $url_content]

	# If user did not enter a title for the bookmark, we need to assign remote page title
	if {[empty_string_p $local_title]} {
	    set user_provided_title_p "f"
	    set local_title $url_title

	    if {[empty_string_p $local_title]} {
		ad_complain "We're sorry but we can not detect a title for this bookmark, 
		the host does not provide one.  If you still want to add this bookmark 
		now, press \[Back\] on your browser and check the URL or type in a title."
	    }
	} else {
	    set user_provided_title_p "t"
	}

    }

} -properties {
    page_title:onevalue
    context:onevalue
    errmsg:onevalue
    local_title:onevalue
    complete_url:onevalue

    parent_id:onevalue
    bookmarks:multirow
    bookmark_id:onevalue

    return_url:onevalue
    url_unreachable_p:onevalue
    meta_description:onevalue
    meta_keywords:onevalue
    export_form_vars_html:onevalue

} -return_errors error_list

if { [info exists error_list] } {
    set n_errors [llength $error_list]
    ad_return_template "complaint"
}


# If this page was called with a bookmarklet some form vars will not be
# provided and we need to set them here. 
if { [empty_string_p $viewed_user_id] } {
    set viewed_user_id $user_id
}
if { [empty_string_p $bookmark_id] } {
    set bookmark_id [db_nextval acs_object_id_seq]
}

# Redirect the user to log in if he has not done so
set this_url_urlenc [ad_urlencode "[ad_conn url]?[export_vars -url {viewed_user_id complete_url local_title return_url bookmark_id}]"]

set user_id [ad_conn user_id]
if { $user_id == "0" } {
    ad_returnredirect "/register/?return_url=$this_url_urlenc"
    ad_script_abort
}



set page_title "Inserting \"[string trim $local_title]\""

set context [bm_context_bar_args [list [list [export_vars -base bookmark-add-import { return_url viewed_user_id }] "Add/Import Bookmarks"] $page_title] $viewed_user_id]

set meta_description [bm_get_html_description $url_content]
set meta_keywords [bm_get_html_keywords $url_content]

set export_form_vars_html [export_vars -form return_url local_title complete_url bookmark_id viewed_user_id meta_description meta_keywords url_title parent_id]

# If the user provided a title and the url is reachable we do not
# ask for a confirmation
if { $url_unreachable_p == "f" && $user_provided_title_p == "t"} {
    ad_returnredirect "bookmark-add-one-2?[export_vars -url {return_url local_title complete_url bookmark_id meta_description meta_keywords url_title viewed_user_id parent_id}]"
    ad_script_abort
} 



