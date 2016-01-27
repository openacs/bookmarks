ALTER TABLE bm_in_closed_p ALTER COLUMN in_closed_p_id TYPE bigint;

DROP FUNCTION IF EXISTS bookmark__toggle_open_close (integer, integer);
DROP FUNCTION IF EXISTS bookmark__update_in_closed_p_one_user (integer, integer);
DROP FUNCTION IF EXISTS bookmark__initialize_in_closed_p (integer, integer, integer);
DROP FUNCTION IF EXISTS bookmark__toggle_open_close_all (integer, boolean, integer);

CREATE OR REPLACE FUNCTION bookmark__toggle_open_close (integer, bigint)
RETURNS integer AS $$
DECLARE
	p_bookmark_id ALIAS FOR $1;		-- in bm_bookmarks.bookmark_id%TYPE,	     
	p_browsing_user_id ALIAS FOR $2;	-- in bm_bookmarks.owner_id%TYPE

BEGIN
	-- Toggle the closed_p flag
	UPDATE bm_in_closed_p SET closed_p = 
	       (
	       SELECT CASE WHEN closed_p = TRUE THEN FALSE ELSE TRUE END
	       FROM bm_in_closed_p 
	       WHERE bookmark_id = p_bookmark_id
	       AND in_closed_p_id = p_browsing_user_id
	       )
	WHERE bookmark_id = p_bookmark_id
	AND in_closed_p_id = p_browsing_user_id;

	-- Now update the in_closed_p status for this user for all bookmarks under
	-- the toggled folder
	perform bookmark__update_in_closed_p_one_user (p_bookmark_id, p_browsing_user_id);
	RETURN 0;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION bookmark__update_in_closed_p_one_user (integer, bigint)
RETURNS integer AS $$
DECLARE
       p_bookmark_id ALIAS FOR $1;	-- in bm_bookmarks.bookmark_id%TYPE,	     
       p_browsing_user_id ALIAS FOR $2;	-- in bm_bookmarks.owner_id%TYPE
       v_parent_ids RECORD;

BEGIN
	-- Update the in_closed_p flag of bookmarks and folders that lie under
	-- the toggled folder in the tree for one particular user/session.
	-- First set all in_closed_p flags to f ...
	UPDATE bm_in_closed_p SET in_closed_p = FALSE
	WHERE bookmark_id IN 
	      (
	      select bm.bookmark_id from bm_bookmarks bm, bm_bookmarks bm2
	      where bm2.bookmark_id = p_bookmark_id
                and bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
	      )
	AND in_closed_p_id = p_browsing_user_id;

	-- then set all in_closed_p flags to t that lie under a closed folder
	FOR v_parent_ids IN
	    select bm.bookmark_id from 
	    bm_bookmarks bm, bm_in_closed_p bip
	    where bm.bookmark_id = bip.bookmark_id
	    and bm.folder_p = 't' 
	    and bip.closed_p = 't'
	    and bip.in_closed_p_id = p_browsing_user_id
	LOOP
		UPDATE bm_in_closed_p set in_closed_p = TRUE 
		WHERE bookmark_id IN 
		(
			select bm.bookmark_id from bm_bookmarks bm, bm_bookmarks bm2
			where bm2.bookmark_id = v_parent_ids.bookmark_id
                          and bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
		INTERSECT
			select bm.bookmark_id from bm_bookmarks bm, bm_bookmarks bm2
			where bm2.bookmark_id = p_bookmark_id
                          and bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
		)
		AND in_closed_p_id = p_browsing_user_id
	        AND bookmark_id <> v_parent_ids.bookmark_id
		AND bookmark_id <> p_bookmark_id;
	END LOOP;
	RETURN 0;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bookmark__initialize_in_closed_p (integer, bigint, integer)
RETURNS integer AS $$
DECLARE
 	p_viewed_user_id ALIAS FOR $1;	-- in users.user_id%TYPE	
 	p_in_closed_p_id ALIAS FOR $2;	-- in users.user_id%TYPE	
	p_package_id ALIAS FOR $3;	-- in apm_packages.package_id%TYPE
	v_root_id bm_bookmarks.bookmark_id%TYPE;
	c_bookmark RECORD;
	v_in_closed_p bm_in_closed_p.in_closed_p%TYPE;
	v_closed_p bm_in_closed_p.closed_p%TYPE;
BEGIN
	-- We want to initialize all bookmarks to the closed state, except for
	-- the root folder. That means we need to have the following settings
	-- based on the tree_level the bookmark/folder is at:
	-- bookmark type  in_closed_p closed_p tree_level
	-- -------------- ----------- -------- ----------
	-- root                f          f         1
	-- top folders/bm      f          t         2
	-- all others          t          t         3+

	-- The bookmarks package can be mounted a number of times, and the same
	-- user can have bookmarks at more than one mount point, so we need to
	-- pick the right root_folder:
	v_root_id := bookmark__get_root_folder(p_package_id, p_viewed_user_id);

	FOR c_bookmark IN
		SELECT bookmark_id, tree_level(tree_sortkey) AS t_level FROM bm_bookmarks
		WHERE owner_id = p_viewed_user_id
		AND bookmark_id IN
		(
			-- Select bookmarks that belong to the root of this package_id only
			SELECT bm.bookmark_id FROM bm_bookmarks bm, bm_bookmarks bm2
			WHERE bm2.bookmark_id = v_root_id
			AND bm.tree_sortkey BETWEEN bm2.tree_sortkey AND tree_right(bm2.tree_sortkey)
		)
		AND bookmark_id NOT IN
		(
			SELECT bookmark_id FROM bm_in_closed_p
			WHERE in_closed_p_id = p_in_closed_p_id
		)
	LOOP
		IF c_bookmark.t_level = 1 THEN
			v_in_closed_p := FALSE;
			   v_closed_p := FALSE;
		ELSIF c_bookmark.t_level = 2 THEN
			v_in_closed_p := FALSE;
			   v_closed_p := TRUE;
		ELSE
			v_in_closed_p := TRUE;
			   v_closed_p := TRUE;
		END IF;

		INSERT INTO bm_in_closed_p (bookmark_id, in_closed_p_id, in_closed_p, closed_p, creation_date)
		VALUES (c_bookmark.bookmark_id, p_in_closed_p_id, v_in_closed_p, v_closed_p, now());
		-- This is not quite right in the case bm_in_closed_p already contains some entries for
		-- this p_in_closed_p_id, but it is no worse than what we had before so it will do for now.
		-- in_closed_p should really be based on the parent folder state -- and the parent folder
		-- must be inserted first.
	   END LOOP;

	   RETURN 0;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION bookmark__toggle_open_close_all (bigint, boolean, integer)
RETURNS integer AS $$
DECLARE
	p_browsing_user_id ALIAS FOR $1;	-- in bm_bookmarks.owner_id%TYPE,
	p_closed_p ALIAS FOR $2;		-- in bm_in_closed_p.closed_p%TYPE default f,
	p_root_id ALIAS FOR $3;			-- in bm_bookmarks.parent_id%TYPE

BEGIN
	-- Change the value of closed_p for all folders belonging to the
	-- user (except the root folder)
	UPDATE bm_in_closed_p SET closed_p = p_closed_p
	WHERE bookmark_id IN 
	(
		SELECT bm.bookmark_id FROM bm_bookmarks bm, bm_bookmarks bm2
		WHERE tree_level(bm.tree_sortkey) > 1
		  and bm2.bookmark_id = p_root_id
                  and bm.tree_sortkey between bm2.tree_sortkey and tree_right(bm2.tree_sortkey)
	); 

	-- Update the value of in_closed_p for all bookmarks belonging to 
	-- this user. We close/open all bookmarks except the top level ones.
	UPDATE bm_in_closed_p SET in_closed_p = p_closed_p
	WHERE bookmark_id IN 
	(
		SELECT bookmark_id FROM bm_bookmarks 
		WHERE  tree_level(tree_sortkey) > 2
	)
	AND in_closed_p_id = p_browsing_user_id;	 	

	RETURN 0;
END;
$$ LANGUAGE plpgsql;
