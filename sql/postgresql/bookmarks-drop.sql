-- 
-- packages/bookmarks/sql/bookmarks-drop.sql
-- 
-- Credit for the ACS 3 version of this module goes to:
-- @author David Hill (dh@arsdigita.com)
-- @author Aurelius Prochazka (aure@arsdigita.com)
--
-- The upgrade of this module to ACS 4 was done by
-- @author Peter Marklund (pmarklun@arsdigita.com)
-- @author Ken Kennedy (kenzoid@io.com)
-- in December 2000.
--
-- @creation-date December 2000
-- @cvs-id $Id

-- Delete all bookmark objects and corresponding acs objects
-- KDK: NB

create function inline_3 ()
returns integer as '
DECLARE
	v_bookmark_id RECORD;
begin
	FOR v_bookmark_id IN select bookmark_id from bm_bookmarks
	    WHERE parent_id NOT IN (select bookmark_id from bm_bookmarks)  
	LOOP
		PERFORM bookmark__delete (v_bookmark_id.bookmark_id);
	END LOOP;
    return 0;
end;' language 'plpgsql';

select inline_3 ();

drop function inline_3 ();

-- declare
--    cursor c_bookmark_id
--    is
--    select bookmark_id
--    from bm_bookmarks
--    where parent_id not in (select bookmark_id from bm_bookmarks);
-- begin	
--    for v_bookmark_id in c_bookmark_id loop
--	bookmark.delete(v_bookmark_id.bookmark_id);
--    end loop;
-- end;
-- /
-- show errors


-- Drop the in_closed_p table
-- KDK: Complete
drop table bm_in_closed_p;

-- KDK: Complete
drop index bm_bookmarks_local_title_idx ;
-- KDK: Complete
drop index bm_bookmarks_access_date_idx ;
-- KDK: Complete
drop index bm_bookmarks_idx1;
-- KDK: Complete
-- drop index bm_bookmarks_idx2;


-- Drop bookmark table and package
-- KDK: Complete
drop table bm_bookmarks;
-- Drop functions used to maintain tree_sortkey for CONNECT AS functionality
-- KDK: Complete
DROP FUNCTION bm_bookmarks_insert_tr ();
DROP FUNCTION bm_bookmarks_update_tr ();
-- KDK: Complete
-- drop package bookmark;
-- KDK: For postgres, drop functions separately
-- (new, delete, name, get_in_closed_p, update_in_closed_p_one_user, update_in_closed_p_all_users,
--  toggle_open_close, toggle_open_close_all, get_root_folder, new_root_folder, private_p, 
--  update_private_p, initialize_in_closed_p)
DROP FUNCTION bookmark__new (integer,integer,integer,varchar,boolean,integer,timestamptz,integer,varchar,integer);
DROP FUNCTION bookmark__delete (integer);
DROP FUNCTION bookmark__name (integer);
DROP FUNCTION bookmark__get_in_closed_p (integer,integer);
DROP FUNCTION bookmark__update_in_closed_p_one_user (integer, integer);
DROP FUNCTION bookmark__update_in_closed_p_all_users (integer, integer);
DROP FUNCTION bookmark__toggle_open_close (integer, integer);
DROP FUNCTION bookmark__toggle_open_close_all (integer, boolean, integer);
DROP FUNCTION bookmark__new_root_folder (integer, integer);
DROP FUNCTION bookmark__get_root_folder (integer, integer);
DROP FUNCTION bookmark__private_p (integer);
DROP FUNCTION bookmark__update_private_p (integer, boolean);
DROP FUNCTION bookmark__initialize_in_closed_p (integer, integer);
DROP FUNCTION bm_bookmarks_get_tree_sortkey(integer);

-- Delete all url objects and corresponding acs objects
-- KDK: Complete

create function inline_2 ()
returns integer as '
DECLARE
	v_url_id RECORD;
begin
	FOR v_url_id IN select url_id from bm_urls 
	LOOP
		PERFORM url__delete (v_url_id.url_id);
	END LOOP;
    return 0;
end;' language 'plpgsql';

select inline_2 ();

drop function inline_2 ();

-- Drop url table and package
-- KDK: Complete
drop table bm_urls;
-- KDK: Complete
-- drop package url;
-- KDK: For postgres, drop functions separately (new, delete, insert_or_update)
DROP FUNCTION url__new(integer,varchar,varchar,varchar,text,text,integer,varchar,integer);
DROP FUNCTION url__delete(integer);
DROP FUNCTION url__insert_or_update(varchar,varchar,varchar,text,text,integer,varchar,integer);


-- Drop the url and bookmark object types
-- KDK: Complete
-- begin
--     acs_object_type.drop_type('url');
--     acs_object_type.drop_type('bookmark');
-- end;
-- /
-- show errors

create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__drop_type (
        ''url'',
        ''f''
        );

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

create function inline_1 ()
returns integer as '
begin
    PERFORM acs_object_type__drop_type (
        ''bookmark'',
        ''f''
        );

    return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


