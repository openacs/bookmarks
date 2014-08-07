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
   viewed_user_id:naturalnum,notnull

} -properties {
    page_title:onevalue
    context:onevalue    

} 

# We are currently only supporting export of the users own bookmarks
if { $viewed_user_id ne [ad_conn user_id] } {
    set n_errors 1
    set error_list [list "We are sorry, but the bookmarks module does not currently support the exporting other users bookmarks."]
    ad_return_template "complaint"
}


set page_title "Export Bookmarks to Netscape File"

set context [bm_context_bar_args [list $page_title] $viewed_user_id]


ad_return_template
