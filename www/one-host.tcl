ad_page_contract {
    Lists the urls and their users with a certain host name.

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

    host_url:notnull
    
} -properties {
    page_title:onevalue
    context:onevalue

    user_urls:multirow
}

set page_title "Bookmarks for $host_url"

set context [list [list "most-popular" "Most Popular"] [ad_quotehtml $page_title]]


set old_name ""
db_multirow user_urls user_urls {
    select u.first_names || ' ' || u.last_name as name, 
           bml.local_title,
           complete_url
    from   cc_users u, 
           bm_bookmarks bml, 
           bm_urls bmu
    where  u.user_id = bml.owner_id
    and    bml.url_id = bmu.url_id
    and    bmu.host_url = :host_url
    order by name
}


ad_return_template







