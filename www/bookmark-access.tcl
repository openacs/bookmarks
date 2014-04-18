ad_page_contract {
    This script updates the access date of the bookmark
    (any other auditing could be done here as well) and
    redirects the user to the url.
    
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
    bookmark_id:integer
    url
}

db_dml update_access_date "update bm_bookmarks set last_access_date = sysdate where bookmark_id = :bookmark_id
or bookmark_id in (select bookmark_id from bm_bookmarks 
start with bookmark_id = (select parent_id from bm_bookmarks where bookmark_id = :bookmark_id) 
connect by prior parent_id = bookmark_id)"

ad_returnredirect  -allow_complete_url "$url"
