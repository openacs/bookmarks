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


drop table bm_in_closed_p;

drop index bm_bookmarks_local_title_idx ;
drop index bm_bookmarks_access_date_idx ;
drop index bm_bookmarks_idx1;
-- drop index bm_bookmarks_idx2;


-- Drop bookmark table and package
drop table bm_bookmarks;
DROP FUNCTION bm_bookmarks_insert_tr ();
DROP FUNCTION bm_bookmarks_update_tr ();

-- Drop all functions named bookmark__.*
SELECT drop_package('bookmark');
DROP FUNCTION bm_bookmarks_get_tree_sortkey(integer);

-- Delete all url objects and corresponding acs objects
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
drop table bm_urls;

-- Drop all functions named url__.*
SELECT drop_package('url');


-- Drop the url and bookmark object types
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


