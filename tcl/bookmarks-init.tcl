ad_library {
    Startup script for the bookmarks module.

    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id$
}



# The table bm_in_closed_p holds session data that needs to be removed
# to avoid the table growing to large (maximum size of the table would be
# number_of_bookmarks times number_of_users)
ad_schedule_proc 86400 bm_clean_up_session_data


ad_proc bm_clean_up_session_data {} {
The table bm_in_closed_p holds session data that needs to be removed
 to avoid the table growing to large (maximum size of the table would be
 number_of_bookmarks times number_of_users)
} {
    set max_days 31
    db_dml delete_old_in_closed_p "delete from bm_in_closed_p where creation_date < (sysdate - :max_days)"
}


