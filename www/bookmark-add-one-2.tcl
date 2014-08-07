ad_page_contract {
    Inserts a single bookmark into the bookmark system.
    Details: 
    1 splits the 'complete_url' to get the 'host_url'
    2 checks if 'complete_url' and implicitly 'host_url' are  already in bm_urls            if not,  inserts them into the table 
    3 inserts the corresponding 'pretty_title', 'bookmark_id', 'parent_id' (along with user_id)  into bm_list

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
    viewed_user_id:naturalnum,notnull
    parent_id:naturalnum,notnull
    complete_url
    local_title
    bookmark_id:naturalnum,notnull
    url_title
    meta_description
    meta_keywords
}

set user_id [ad_conn user_id]

permission::require_permission -object_id $parent_id -privilege write

# split the url to get the host_url
set host_url [bm_host_url $complete_url]


# Check if the input url is already in the database. If the url is already in the database
# we fetch the corresponding url_id, and if not we insert the url remembering the url_id. 
#------------------------------------------------------------------------------------------
set n_complete_urls [db_string count_url "
    select count(*)
    from   bm_urls
    where  complete_url = :complete_url "]

set creation_ip [ad_conn peeraddr]

if {$n_complete_urls == 0} {
   
        set url_id [db_nextval acs_object_id_seq]

	db_exec_plsql url_add "
	begin
	   :1 := url.new (
           url_id => :url_id,
           url_title => :url_title,
	   host_url => :host_url,
	   complete_url => :complete_url,
           meta_keywords => :meta_keywords,
           meta_description => :meta_description,
           creation_user => :viewed_user_id,
           creation_ip => :creation_ip
	);
	end;"

} else {
    set url_id [db_string new_url_id "select url_id 
                                      from   bm_urls 
                                      where  complete_url= :complete_url"]

    db_dml update_url_meta_info "update bm_urls set url_title= :url_title,
	    meta_description= :meta_description,
	    meta_keywords= :meta_keywords
            where url_id = :url_id"
}
#------------------------------------------------------------------------------------------


# Insert the bookmark
#------------------------------------------------------------------------------------------
    if {[catch {db_exec_plsql bookmark_add "
    declare
      dummy_var integer;
    begin
      dummy_var := bookmark.new (
       bookmark_id => :bookmark_id,
       owner_id    => :viewed_user_id,
       url_id      => :url_id,
       local_title => :local_title,
       parent_id   => :parent_id,
       creation_user => :user_id,
       creation_ip => :creation_ip
	);       
    end;"} errmsg]} {
	bm_handle_bookmark_double_click $bookmark_id $errmsg $return_url
    }
#------------------------------------------------------------------------------------------
 

ad_returnredirect "$return_url"




