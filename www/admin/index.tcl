ad_page_contract {
    Entry page for the admin pages of the bookmarks module. 

    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id:
} -properties {
    page_title:onevalue
    context:onevalue
}

# Do we have to check for admin permissions here?

set page_title "Bookmarks System Administration"

set context {}


ad_return_template







