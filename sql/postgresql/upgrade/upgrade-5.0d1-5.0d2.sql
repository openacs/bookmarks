--

-- @author Gabriel Burca (gburca-openacs@ebixio.com)
-- @creation-date 2004-06-22
-- @cvs-id $Id$
--

create or replace function bm_bookmarks_get_folder_names(
	--
	-- Returns the names of the parent folders of a bookmark, joined
	-- together with an optional separator.
	--
	-- @author Gabriel Burca (gburca-openacs@ebixio.com)
	--

	integer,	-- bm_bookmarks.bookmark_id%TYPE
	text		-- Optional separator (set to NULL to use the default)
) returns text as '
declare
	p_bookmark_id	alias for $1;
	p_sep		alias for $2;	-- optional separator to use
	v_rec		record;
	tree_key	varbit;
	separator	text default '' :: '';
	folder_names	text default '''';	-- If NULL, the || in the LOOP fails
begin
	tree_key := bm_bookmarks_get_tree_sortkey(p_bookmark_id);
	
	-- Level 1 is the root folder, level 2 is items in the root folder
	if tree_level(tree_key) <= 2 then
		return '''';
	end if;
	
	if p_sep is not null then
		separator := p_sep;
	end if;

	for v_rec in select local_title
		from bm_bookmarks
		where tree_sortkey in
			(select tree_ancestor_keys( -- get all parent folders up to level 2
					tree_ancestor_key(	-- start with the parent folder key
						tree_key, tree_level(tree_key) - 1), 2 ) )
		order by tree_sortkey
	LOOP
		folder_names := folder_names || separator || v_rec.local_title;
	end LOOP;

	return trim(leading separator from folder_names);
end;' language 'plpgsql';


DROP FUNCTION bookmark__initialize_in_closed_p (integer, integer);

CREATE FUNCTION bookmark__initialize_in_closed_p (integer, integer, integer)
RETURNS integer AS '
DECLARE
 	p_viewed_user_id	ALIAS FOR $1;	-- in users.user_id%TYPE,	
 	p_in_closed_p_id	ALIAS FOR $2;	-- in users.user_id%TYPE	
	p_package_id		ALIAS FOR $3;	-- in apm_packages.package_id%TYPE
	v_root_id		bm_bookmarks.bookmark_id%TYPE;
	c_bookmark		RECORD;
	v_in_closed_p		bm_in_closed_p.in_closed_p%TYPE;
	v_closed_p		bm_in_closed_p.closed_p%TYPE;
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
' LANGUAGE 'plpgsql';

