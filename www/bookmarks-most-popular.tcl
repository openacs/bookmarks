ad_page_contract {
    List the most popular hosts and urls (includes the
    most-popular-selection template).

    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id$
} -properties {
    page_title:onevalue
    context:onevalue
}

set page_title "Most Popular Bookmarks"

set context [list $page_title]


ad_return_template







