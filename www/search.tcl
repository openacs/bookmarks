ad_page_contract {

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
    viewed_user_id:integer
    return_url
    search_text:notnull

} -validate {

    no_just_wildcard -requires {search_text:notnull} {
	if [regexp {^%+$} $search_text] {
	    ad_complain "Please search for more than just a wildcard."
	}
    }

} -properties {
    page_title:onevalue
    context:onevalue
    search_text:onevalue
    
    return_url:onevalue

    browsing_user_id:onevalue
    viewed_user_id:onevalue

    my_list:multirow
    others_list:multirow

} -return_errors error_list

if { [info exists error_list] } {
    set n_errors [llength $error_list]
    ad_return_template "complaint"
    return
}

set page_title "Searching for \"$search_text\""
set context [bm_context_bar_args "\"[ad_quotehtml $page_title]\"" $viewed_user_id]

set package_id [ad_conn package_id]

set root_folder_id [bm_get_root_folder_id $package_id $viewed_user_id]

set browsing_user_id [ad_conn user_id]

set search_pattern "%[string toupper $search_text]%"

multirow create my_list bookmark_id complete_url title
multirow create others_list bookmark_id complete_url title admin_p


# this select gets all of the users bookmarks that match the user's request
set bookmark_count 0
set bookmark_html ""

db_foreach bookmark_search_user {
    select   bookmark_id, 
             complete_url,
             nvl(local_title, url_title) as title, 
             meta_keywords, 
             meta_description
    from     (select bookmark_id, url_id, local_title, folder_p, owner_id 
              from bm_bookmarks start with bookmark_id = :root_folder_id 
              connect by prior bookmark_id = parent_id) b, 
             bm_urls
    where    owner_id = :browsing_user_id 
    and      folder_p = 'f'
    and      b.url_id = bm_urls.url_id 
    and      b.bookmark_id <> :root_folder_id
    and     (    upper(local_title)      like :search_pattern
              or upper(url_title)        like :search_pattern
              or upper(complete_url)     like :search_pattern
              or upper(meta_keywords)    like :search_pattern
              or upper(meta_description) like :search_pattern)
    order by title
} {
    incr bookmark_count

    multirow append my_list $bookmark_id $complete_url $title

}


# thie query searches across other peoples bookmarks that the browsing user
# has read permission on

set bookmark_count 0
set bookmark_html ""

db_foreach bookmark_search_other {
    select   distinct complete_url,
             bookmark_id,
             nvl(local_title, url_title) as title, 
             meta_keywords, 
             meta_description, 
             folder_p,
             acs_permission.permission_p(bookmark_id, :browsing_user_id, 'admin') as admin_p
    from     (select bookmark_id, url_id, local_title, folder_p, owner_id 
              from bm_bookmarks start with bookmark_id in (select bookmark_id
                           from bm_bookmarks where parent_id = :package_id)
              connect by prior bookmark_id = parent_id) b, 
             bm_urls
    where    owner_id <> :browsing_user_id
    and      acs_permission.permission_p(bookmark_id, :browsing_user_id, 'read') = 't'
    and      folder_p  = 'f' 
    and      b.url_id = bm_urls.url_id 
    and     (   upper(local_title)      like :search_pattern
             or upper(url_title)        like :search_pattern
             or upper(complete_url)     like :search_pattern
             or upper(meta_keywords)    like :search_pattern
             or upper(meta_description) like :search_pattern)
    order by title
} {
    multirow append others_list $bookmark_id $complete_url $title $admin_p
}



