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



