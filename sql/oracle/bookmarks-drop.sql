-- 
-- packages/bookmarks/sql/bookmarks-create.sql
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
declare
    cursor c_bookmark_id
    is
    select bookmark_id
    from bm_bookmarks
    where parent_id not in (select bookmark_id from bm_bookmarks);
begin	
    for v_bookmark_id in c_bookmark_id loop
	bookmark.del(v_bookmark_id.bookmark_id);
    end loop;
end;
/
show errors


-- Drop the in_closed_p table
drop table bm_in_closed_p;

drop index bm_bookmarks_local_title_idx ;
drop index bm_bookmarks_access_date_idx ;
drop index bm_bookmarks_idx1;
drop index bm_bookmarks_idx2;


-- Drop bookmark table and package
drop table bm_bookmarks;
drop package bookmark;


-- Delete all url objects and corresponding acs objects
declare
    cursor c_url_id
    is
    select url_id
    from bm_urls;
begin	
    for v_url_id in c_url_id loop
	url.del(v_url_id.url_id);
    end loop;
end;
/
show errors

-- Drop url table and package
drop table bm_urls;
drop package url;




-- Drop the url and bookmark object types
begin
    acs_object_type.drop_type('url');
    acs_object_type.drop_type('bookmark');
end;
/
show errors


