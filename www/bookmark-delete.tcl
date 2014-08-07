ad_page_contract {
    This page asks for confirmation before a bookmark
    (and all its contained bookmarks) are deleted.

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
    viewed_user_id:naturalnum,notnull
    return_url

} -properties {
    page_title:onevalue
    context:onevalue
    bookmark_title:onevalue
    contained_bookmarks:multirow
    return_url
}

# We have to check delete permission on all contained bookmarks as well
bm_require_delete_permission $bookmark_id


set page_title "Confirm Deletion"

set context [list [list bookmark-edit?bookmark_id=$bookmark_id&viewed_user_id=$viewed_user_id "Edit Bookmark"] $page_title]

set bookmark_title [db_string bookmark_title "select local_title from bm_bookmarks
                                              where bookmark_id = :bookmark_id"]


db_multirow contained_bookmarks contained_bookmarks {select local_title, level as indentation 
from bm_bookmarks start with bookmark_id = :bookmark_id 
connect by prior bookmark_id = parent_id}


ad_return_template



