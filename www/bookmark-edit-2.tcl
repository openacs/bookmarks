ad_page_contract {
    Makes changes to the bookmark and redirects to the
    index page

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
    folder_p
    return_url
    bookmark_id:naturalnum,notnull
    viewed_user_id:naturalnum,notnull
    {complete_url:trim ""}
    local_title
    parent_id:naturalnum,notnull
    {private_p "f"}
    old_private_p
} -validate {
    valid_url {
	if { $folder_p == "f" && [string trim $complete_url] eq "" } {
	    ad_complain "You must provide a non empty url"
	}
    }

} -return_errors error_list

if { [info exists error_list] } {
    set n_errors [llength $error_list]
    ad_return_template "complaint"
    return
}


permission::require_permission -object_id $bookmark_id -privilege admin

# We update or insert the url
if {$folder_p == "f"} {

    set host_url [bm_host_url $complete_url]
    set creation_ip [ad_conn peeraddr]
    set creation_user [ad_conn user_id]

    set url_id [db_exec_plsql insert_or_update_url "
    begin
    :1 := url.insert_or_update (
    url_title => :local_title,
    host_url => :host_url,
    complete_url => :complete_url,
    creation_user => :creation_user,
    creation_ip => :creation_ip
    );
    end;"]

    set url_clause [db_map url_clause]
} else {
    set url_clause ""
}

# Update the title, url_id and parent id of the bookmark
db_dml update_bookmark "update bm_bookmarks set local_title = :local_title, parent_id = :parent_id
                        $url_clause
                        where bookmark_id = :bookmark_id"

# Also update the context id of the bookmark
db_dml update_context_id "update acs_objects set context_id = :parent_id where object_id = :bookmark_id"

# Since the bookmark may have been moved we need to update its
# in_closed_p status for all users viewing the bookmark tree
db_exec_plsql update_in_closed_p_all_users "
begin
bookmark.update_in_closed_p_all_users (
                bookmark_id => :bookmark_id,
                new_parent_id => :parent_id
);
end;"

# Update the private_p status of the bookmark
if { $old_private_p ne $private_p } {
    bm_update_bookmark_private_p $bookmark_id $private_p
}


ad_returnredirect "$return_url"
