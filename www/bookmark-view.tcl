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
    bookmark_id:naturalnum,notnull

} -properties {
    page_title:onevalue
    context:onevalue

}

set page_title "View Bookmark"

set context [list $page_title]

permission::require_permission -object_id $bookmark_id -privilege read


template::query bookmark_view bookmark onerow "select local_title,
               email,
               owner_id,
               complete_url, 
               bookmark_id,
               meta_keywords,
               meta_description,
               url_title
        from   bm_bookmarks, 
               bm_urls,
               parties
        where  bookmark_id = :bookmark_id
        and    bm_bookmarks.url_id = bm_urls.url_id(+)
        and    bm_bookmarks.owner_id = parties.party_id"

ad_return_template












