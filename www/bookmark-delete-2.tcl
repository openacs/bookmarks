ad_page_contract {
    This script deletes a bookmark and redirects to the 
    index page.

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
    return_url
} 

bm_require_delete_permission $bookmark_id


if [catch {db_exec_plsql bookmark_delete "
    begin
      bookmark.delete (
       bookmark_id => :bookmark_id
	);       
 end;"} errmsg] {

     set n_errors 1
     set error_list [list "We were not able to delete the bookmark from the database, this is the error message: <pre>$errmsg</pre>"]

     ad_return_template "error"
     return
}


ad_returnredirect $return_url
