-- packages/bookmarks/sql/postgresql/upgrade/upgrade-4.1.1b-4.6.sql
--
-- @author Vinod Kurup (vinod@kurup.com)
-- @creation_date 2002-10-08
--
-- $Id$

CREATE OR REPLACE FUNCTION bookmark__delete (integer)
RETURNS integer AS '
DECLARE
	p_bookmark_id ALIAS FOR $1;	-- in bm_bookmarks.bookmark_id%TYPE,
	c_bookmark_id_tree RECORD;
	c_bookmark_id_one_level RECORD;
BEGIN

 	FOR c_bookmark_id_tree IN 
	    select bm.bookmark_id,
	    (select case when count(*)=0 then 1 else 0 end from 
	    bm_bookmarks where parent_id = bm.bookmark_id) as is_leaf_p
	    from bm_bookmarks bm, bm_bookmarks bm2
            where bm2.bookmark_id = p_bookmark_id
	      and bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
            order by tree_level(bm.tree_sortkey) desc, is_leaf_p desc, bm.tree_sortkey
 	LOOP

            -- DRB: This query is insane in both its PG and Oracle versions but I do not
            -- have time to improve it at the moment ... 

	    FOR c_bookmark_id_one_level IN 
	    select bookmark_id
	    from bm_bookmarks bm_outer
	    where parent_id = 
	    (
		select parent_id from bm_bookmarks where bookmark_id = c_bookmark_id_tree.bookmark_id
	    )
	    and not exists 
	    (
		select 1 from bm_bookmarks where parent_id = bm_outer.bookmark_id
	    )
	    and bm_outer.bookmark_id in 
	    (
		select bm.bookmark_id from bm_bookmarks bm, bm_bookmarks bm2
		where bm2.bookmark_id = p_bookmark_id
                  and bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey) 
		order by bm.tree_sortkey
	    )
 	    LOOP
		delete from acs_permissions where object_id = c_bookmark_id_one_level.bookmark_id;
		delete from bm_in_closed_p where bookmark_id = c_bookmark_id_one_level.bookmark_id;
		delete from bm_bookmarks where bookmark_id = c_bookmark_id_one_level.bookmark_id;
 		perform acs_object__delete(c_bookmark_id_one_level.bookmark_id);
 	    END LOOP;
 	END LOOP;
	RETURN 0;
END;
' LANGUAGE 'plpgsql';


