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
    bookmark_id:naturalnum,notnull
    url
}

set complete_url [db_string get_url {
    select complete_url from bm_urls u, bm_bookmarks b
    where  b.bookmark_id = :bookmark_id
    and    b.url_id = u.url_id
} -default ""]

if {$complete_url ne $url} {
    ad_log warning "attempt to use OpenACS as URL redirector to: $url"
}

if {$complete_url ne ""} {
    db_dml update_access_date {}
    ad_returnredirect  -allow_complete_url $complete_url
} else {
    ad_return_error "Invalid bookmark_id" "No bookmark URL available for this bookmark_id"
}
ad_script_abort
