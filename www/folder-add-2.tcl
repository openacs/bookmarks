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
    return_url
    local_title:notnull
    bookmark_id:integer
    parent_id:integer
    viewed_user_id:integer
}


# Insert the folder

# First fetch necessary variables
set creation_ip [ad_conn peeraddr]
set user_id [ad_conn user_id]

ad_require_permission $parent_id write

set folder_p "t"
set closed_p "f"

if [catch {db_exec_plsql bookmark_add "
declare
dummy_var integer;
begin
dummy_var := bookmark.new (
bookmark_id => :bookmark_id,
owner_id    => :viewed_user_id,
local_title => :local_title,
parent_id   => :parent_id,
folder_p    => :folder_p,
creation_user => :user_id,
creation_ip => :creation_ip
);       
end;"} errmsg] {

    bm_handle_bookmark_double_click $bookmark_id $errmsg $return_url
}


ad_returnredirect $return_url
