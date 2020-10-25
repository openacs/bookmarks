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

-- since many people will be bookmarking the same sites, we keep urls in a separate table
create table bm_urls (
	url_id			integer 
				constraint bm_urls_url_id_fk
				references acs_objects (object_id)
				constraint bm_urls_url_id_pk
				primary key,
	-- url title may be null in the case of bookmarks that are merely icons ie. AIM
	url_title		varchar(500),
	-- host url is separated from complete_url for counting purposes
	host_url		varchar(100) 
				constraint bm_urls_host_url_nn
				not null,
	complete_url 		varchar(500) 
				constraint bm_urls_complete_url_nn
				not null,
	-- meta tags that could be looked up regularly	
	meta_keywords 		text,
	meta_description 	text,
	last_checked_date 	timestamptz,
	-- the last time the site returned a "live" status
	last_live_date		timestamptz
);

create function inline_0 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
        ''url'',
        ''URL'',
        ''URLs'',
        ''acs_object'',
        ''bm_urls'',
        ''url_id'',
        null,
        ''f'',
        null,
        null
        );

    return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();

create table bm_bookmarks (
	bookmark_id		integer
				constraint bm_bookmarks_bookmark_id_fk
				references acs_objects (object_id) on delete cascade
				constraint bm_bookmarks_bookmark_id_pk
				primary key,
	owner_id		integer 
				constraint bm_bookmarks_owner_id_nn
				not null 
				constraint bm_bookmarks_owner_id_fk
				references users (user_id),
	-- url_id may be null if the bookmark is a folder
	url_id			integer 
				constraint bm_bookmarks_url_id_fk
				references bm_urls (url_id) ,
	-- a person may rename any of his bookmarks so we keep a local title
	local_title 		varchar(500),
	-- this is 't' if the bookmark is a folder
	folder_p 		boolean default 'f', 
	-- null parent_id indicates this is a top level folder/bookmark
	parent_id 		integer 
				constraint bm_bookmarks_parent_id_fk
				references acs_objects (object_id),
	-- When the bookmark was last clicked on
	last_access_date	timestamptz,
        tree_sortkey            varbit
);


-- We use these index for sorting the bookmarks tree
-- KDK: Functional indices in postgres presently must be only single column indices
--Change create index bm_bookmarks_local_title_idx on bm_bookmarks (parent_id, lower(local_title), bookmark_id); to:

create index bm_bookmarks_local_title_idx on bm_bookmarks (lower(local_title));

-- KDK: The other columns from the original Oracle index are handled by bm_bookmarks_access_date_idx (for parent_id), and the primary key (for bookmark_id)

create index bm_bookmarks_access_date_idx on bm_bookmarks (parent_id, last_access_date, bookmark_id);


-- For connect by queries
-- Replace oracle indexes:
-- create index bm_bookmarks_idx1 on bm_bookmarks(bookmark_id, parent_id);
-- create index bm_bookmarks_idx2 on bm_bookmarks(parent_id, bookmark_id);
-- With index on tree_sortkey
create index bm_bookmarks_idx1 on bm_bookmarks(tree_sortkey);

create function bm_bookmarks_get_tree_sortkey(integer) returns varbit as '
declare
  p_bookmark_id    alias for $1;
begin
  return tree_sortkey from bm_bookmarks where bookmark_id = p_bookmark_id;
end;' language 'plpgsql';

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

create function bm_bookmarks_insert_tr () returns trigger as '
declare
        v_parent_sk     varbit default null;
        v_max_value     integer;
begin
        if new.parent_id is null then 
            select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value 
              from bm_bookmarks 
             where parent_id is null;
        else 
            select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value 
              from bm_bookmarks 
             where parent_id = new.parent_id;

            select tree_sortkey into v_parent_sk 
              from bm_bookmarks 
             where bookmark_id = new.parent_id;
        end if;


        new.tree_sortkey := tree_next_key(v_parent_sk, v_max_value);

        return new;

end;' language 'plpgsql';


create trigger bm_bookmarks_insert_tr before insert 
on bm_bookmarks for each row 
execute procedure bm_bookmarks_insert_tr ();

create function bm_bookmarks_update_tr () returns trigger as '
declare
        v_parent_sk     varbit default null;
        v_max_value     integer;
        ctx_id          integer;
        v_rec           record;
        clr_keys_p      boolean default ''t'';
begin
        if new.bookmark_id = old.bookmark_id and 
           ((new.parent_id = old.parent_id) or
            (new.parent_id is null and old.parent_id is null)) then

           return new;

        end if;

        for v_rec in select bookmark_id
                       from bm_bookmarks 
                      where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey)
                   order by tree_sortkey
        LOOP
            if clr_keys_p then
               update bm_bookmarks set tree_sortkey = null
               where tree_sortkey between new.tree_sortkey and tree_right(new.tree_sortkey);
               clr_keys_p := ''f'';
            end if;
            
            select parent_id into ctx_id
              from bm_bookmarks 
             where bookmark_id = v_rec.bookmark_id;

            if ctx_id is null then 
                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from bm_bookmarks 
                 where parent_id is null;
            else 
                select max(tree_leaf_key_to_int(tree_sortkey)) into v_max_value
                  from bm_bookmarks 
                 where parent_id = ctx_id;

                select tree_sortkey into v_parent_sk 
                  from bm_bookmarks 
                 where bookmark_id = ctx_id;
            end if;

            update bm_bookmarks 
               set tree_sortkey = tree_next_key(v_parent_sk, v_max_value)
             where bookmark_id = v_rec.bookmark_id;

        end LOOP;

        return new;

end;' language 'plpgsql';

create trigger bm_bookmarks_update_tr after update 
on bm_bookmarks
for each row 
execute procedure bm_bookmarks_update_tr ();


create function inline_1 ()
returns integer as '
begin
    PERFORM acs_object_type__create_type (
        ''bookmark'',
        ''Bookmark'',
        ''Bookmarks'',
        ''acs_object'',
        ''bm_bookmarks'',
        ''bookmark_id'',
        null,
        ''f'',
        null,
        ''bookmark__name''
        );

    return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


-- We need this table to keep track of which bookmarks are in a closed folder (they
-- are not to be displayed)
-- This has to be done on a per user (or per session) basis so we can not store
-- this information in the bm_bookmarks table (otherwise we would have problems when
-- two users view the same bookmarks concurrently).
create table bm_in_closed_p (
       bookmark_id	    integer 
			    constraint bm_in_closed_p_bookmark_id_nn
			    not null
			    constraint bm_in_closed_p_bookmark_id_fk
			    references bm_bookmarks (bookmark_id),
       in_closed_p_id	    bigint 
			    constraint bm_in_closed_p_id_nn
			    not null, 
       in_closed_p	    boolean default 't', 
			    
       -- We might want to clean up old rows in this table since it could
       -- easily grow very large in big communities sharing bookmarks actively
       -- refers to whether a folder is open or closed
       closed_p		    boolean default 't', 
       creation_date	    timestamptz,
       constraint bm_in_closed_p_pk
       primary key (bookmark_id, in_closed_p_id)
); 


comment on column bm_in_closed_p.in_closed_p_id is '
 This is the user_id for registered users and the session_id in sec_sessions
 for non-registered users.
';


create unique index bm_in_closed_p_idx on bm_in_closed_p (bookmark_id, in_closed_p_id, in_closed_p);

--KDK: here!

CREATE FUNCTION url__new (integer,varchar,varchar,varchar,text,text,integer,varchar,integer)
RETURNS integer AS '
DECLARE
       p_url_id ALIAS FOR $1;	
       p_url_title ALIAS FOR $2;
       p_host_url	ALIAS FOR $3;	-- default null
       p_complete_url ALIAS FOR $4;
       p_meta_keywords ALIAS FOR $5;	-- default null
       p_meta_description ALIAS FOR $6;	-- default null
       p_creation_user ALIAS FOR $7;	-- default null
       p_creation_ip ALIAS FOR $8;	-- default null
       p_context_id ALIAS FOR $9;	-- default null
       v_url_id integer;
BEGIN
   v_url_id := acs_object__new(p_url_id,''url'',now(),p_creation_user,p_creation_ip,p_context_id);

   insert into bm_urls 
	  (url_id, url_title, host_url, complete_url, meta_keywords, meta_description)
   values 
	  (v_url_id, p_url_title, p_host_url, p_complete_url, p_meta_keywords, p_meta_description);
	     
   return v_url_id;     

END;
' LANGUAGE 'plpgsql';

CREATE FUNCTION url__delete (integer)
RETURNS integer AS '
DECLARE
       p_url_id ALIAS FOR $1;	
BEGIN
   PERFORM acs_object__delete(p_url_id);
	     
   return 0;     

END;
' LANGUAGE 'plpgsql';

CREATE FUNCTION url__insert_or_update (varchar,varchar,varchar,text,text,integer,varchar,integer)
RETURNS integer AS '
DECLARE
       p_url_title ALIAS FOR $1;		-- in bm_urls.url_title%TYPE,
       p_host_url ALIAS FOR $2;			-- in bm_urls.host_url%TYPE default null,
       p_complete_url ALIAS FOR $3;		-- in bm_urls.complete_url%TYPE,
       p_meta_keywords ALIAS FOR $4;		-- in bm_urls.meta_keywords%TYPE default null,
       p_meta_description ALIAS FOR $5;		-- in bm_urls.meta_description%TYPE default null,
       p_creation_user ALIAS FOR $6;		-- in acs_objects.creation_user%TYPE default null, 
       p_creation_ip ALIAS FOR $7;		-- in acs_objects.creation_ip%TYPE default null, 
       p_context_id ALIAS FOR $8;		-- in acs_objects.context_id%TYPE default null        
       v_n_complete_urls integer;
       v_return_id integer;
       v_new_url_id integer;
BEGIN
	select count(*) into v_n_complete_urls 
	from bm_urls where bm_urls.complete_url = p_complete_url;

	if v_n_complete_urls = 0 then

	   select nextval(''t_acs_object_id_seq'') into v_new_url_id from dual;

	   v_return_id := url__new(
		       v_new_url_id,
		       p_url_title,
		       p_host_url,
		       p_complete_url,
		       null,
		       null,
		       p_creation_user,
		       p_creation_ip,
		       null
		       );

	   return v_return_id;

      else
	    select url_id into v_return_id from bm_urls where bm_urls.complete_url= p_complete_url;
	    return v_return_id;
      end if;
END;
' LANGUAGE 'plpgsql';

CREATE FUNCTION bookmark__new (integer,integer,integer,varchar,boolean,integer,timestamptz,integer,varchar,integer)
RETURNS integer AS '
DECLARE
	p_bookmark_id ALIAS FOR $1;		-- in bm_bookmarks.bookmark_id%TYPE, 
	p_owner_id ALIAS FOR $2;		-- in bm_bookmarks.owner_id%TYPE, 
	p_url_id ALIAS FOR $3;			-- in bm_urls.url_id%TYPE default null, 
	p_local_title ALIAS FOR $4;		-- in bm_bookmarks.local_title%TYPE default null,
	p_folder_p ALIAS FOR $5;		-- in bm_bookmarks.folder_p%TYPE default f, 
	p_parent_id ALIAS FOR $6;		-- in bm_bookmarks.parent_id%TYPE, 
        p_last_access_date ALIAS FOR $7;	-- in bm_bookmarks.last_access_date%TYPE default null,
	p_creation_user ALIAS FOR $8;		-- in acs_objects.creation_user%TYPE default null, 
	p_creation_ip ALIAS FOR $9;		-- in acs_objects.creation_ip%TYPE default null, 
	p_context_id ALIAS FOR $10;		-- in acs_objects.context_id%TYPE default null        

	v_bookmark_id integer;
	v_last_access_date bm_bookmarks.last_access_date%TYPE;
	v_in_closed_p bm_in_closed_p.in_closed_p%TYPE;

	c_viewing_in_closed_p_ids RECORD;
	
BEGIN
	v_bookmark_id := acs_object__new(
		      p_bookmark_id,
		      ''bookmark'',
		      now(),
		      p_creation_user,
		      p_creation_ip,
		      p_parent_id
		      );

	if p_last_access_date is null then
	   select now() into v_last_access_date;
	else
	   v_last_access_date := p_last_access_date;   
	end if;			   

	insert into bm_bookmarks
	      (bookmark_id, owner_id, url_id, local_title, 
	      folder_p, parent_id, last_access_date)
	   values
	      (v_bookmark_id, p_owner_id, p_url_id, p_local_title, 
	      p_folder_p, p_parent_id, v_last_access_date); 

	FOR c_viewing_in_closed_p_ids IN
	    select distinct in_closed_p_id 
	    from bm_in_closed_p 
	    where bookmark_id = (select parent_id from bm_bookmarks 
			     where bookmark_id = v_bookmark_id)
	LOOP
	    -- For each user or session record the in_closed_p status of
	    -- the bookmark
	    select bookmark__get_in_closed_p (p_parent_id, c_viewing_in_closed_p_ids.in_closed_p_id)
		   into v_in_closed_p;

	    insert into bm_in_closed_p (bookmark_id, in_closed_p_id, in_closed_p, creation_date)
			values (v_bookmark_id, c_viewing_in_closed_p_ids.in_closed_p_id, v_in_closed_p, now()); 
	    
	END LOOP;
	
	RETURN v_bookmark_id;      

END;
' LANGUAGE 'plpgsql';

CREATE FUNCTION bookmark__delete (integer)
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


CREATE OR REPLACE FUNCTION bookmark__name (
       p_object_id integer
) RETURNS varchar AS $$
DECLARE
	v_name	bm_bookmarks.local_title%TYPE;
BEGIN
	select local_title into v_name
	from bm_bookmarks
	     where bookmark_id = p_object_id;

	return v_name;
END;
$$ LANGUAGE plpgsql;

-- Fix for bug 1491, 1653. This function did not always return the true value of closed_p.
CREATE OR REPLACE FUNCTION bookmark__get_in_closed_p (
       p_new_parent_id integer,
       p_user_id integer
) RETURNS boolean AS $$
DECLARE
	v_return_value bm_in_closed_p.in_closed_p%TYPE;
	v_count integer;
BEGIN
	SELECT count(*) INTO v_count
	FROM bm_in_closed_p
	WHERE bookmark_id = p_new_parent_id
	AND in_closed_p_id = p_user_id;

	IF v_count > 0 THEN
		SELECT closed_p INTO v_return_value
		FROM bm_in_closed_p
		WHERE bookmark_id = p_new_parent_id
		AND in_closed_p_id = p_user_id;
	ELSE
		-- This needs to match the default closed_p value from
		-- bookmark__initialize_in_closed_p (which is TRUE for all
		-- except the root folder itself).
		v_return_value := TRUE;
	END IF;

	return v_return_value;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bookmark__update_in_closed_p_one_user (
       p_bookmark_id integer,
       p_browsing_user_id bigint
) RETURNS integer AS $$
DECLARE
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


CREATE OR REPLACE FUNCTION bookmark__update_in_closed_p_all_users (
       p_bookmark_id integer,
       p_new_parent_id integer
) RETURNS integer AS $$
DECLARE
	c_viewing_in_closed_p_ids RECORD;

BEGIN
	FOR c_viewing_in_closed_p_ids IN
	select distinct in_closed_p_id 
	from bm_in_closed_p 
	where bookmark_id = (select bookmark_id from bm_bookmarks 
			     where bookmark_id = p_bookmark_id) 
	LOOP	
	    -- Update the in_closed_p status for this user/session for all bookmarks
	    -- under the folder
	    perform bookmark__update_in_closed_p_one_user (p_bookmark_id, c_viewing_in_closed_p_ids.in_closed_p_id);
	END LOOP;
	RETURN 0;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION bookmark__toggle_open_close (
       p_bookmark_id integer,
       p_browsing_user_id bigint)
RETURNS integer AS $$
DECLARE
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

CREATE OR REPLACE FUNCTION bookmark__toggle_open_close_all (
       p_browsing_user_id bigint,
       p_closed_p boolean,
       p_root_id integer
) RETURNS integer AS $$
DECLARE
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


CREATE FUNCTION bookmark__new_root_folder (
       p_package_id integer,
       p_user_id integer
) RETURNS integer AS $$
DECLARE
	v_folder_id	bm_bookmarks.bookmark_id%TYPE;
	v_bookmark_id   bm_bookmarks.bookmark_id%TYPE;
	v_email		parties.email%TYPE;
	v_local_title	bm_bookmarks.local_title%TYPE;

BEGIN
	SELECT nextval('t_acs_object_id_seq') INTO v_bookmark_id FROM dual;
        
	SELECT email INTO v_email 
	FROM parties where party_id = p_user_id;

	v_local_title := ' Bookmarks Root Folder of ' || v_email;
	v_folder_id := bookmark__new (
		    v_bookmark_id,
		    p_user_id,
		    null,
		    v_local_title,
		    't',
		    p_package_id,
		    null,
		    null,
		    null,
		    null);

		    -- bookmark_id => v_bookmark_id,
		    -- owner_id    => p_user_id,
		    -- folder_p => t,
		    -- local_title => Bookmarks Root Folder of || v_email,
		    -- parent_id   => new_root_folder.package_id
    
        -- set up default permissions
	-- The owner may administer the bookmarks
	-- Any other permissions will be inherited from the next higher
	-- package instance in the site hierarchy
	PERFORM acs_permission__grant_permission (
		v_folder_id,
		p_user_id,
		'admin');
	
		-- object_id => v_folder_id,
		-- grantee_id => new_root_folder.user_id,
		-- privilege => admin

	RETURN v_folder_id;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bookmark__get_root_folder (
       p_package_id integer,
       p_user_id integer
) RETURNS integer AS $$
DECLARE
	v_folder_id	bm_bookmarks.bookmark_id%TYPE;
	v_count		integer;    

BEGIN
	SELECT count(*) INTO v_count 
	FROM bm_bookmarks
	WHERE parent_id = p_package_id
	AND   owner_id = p_user_id;

	IF v_count > 0 THEN
	    SELECT bookmark_id INTO v_folder_id 
	    FROM bm_bookmarks
	    WHERE parent_id = p_package_id
	    AND owner_id = p_user_id;
	ELSE
	    -- must be a new instance.  Gotta create a new root folder
	    v_folder_id := bookmark__new_root_folder (p_package_id, p_user_id);
	END IF;

	RETURN v_folder_id;


END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION bookmark__private_p (
       p_bookmark_id integer
) RETURNS boolean AS $$
DECLARE
	v_private_p  bm_in_closed_p.closed_p%TYPE;

BEGIN

	SELECT CASE WHEN count(*)=0 THEN 'f' ELSE 't' END INTO v_private_p
	FROM acs_objects, 
	(
		SELECT bm.bookmark_id FROM bm_bookmarks bm,
                  (SELECT tree_ancestor_keys(bm_bookmarks_get_tree_sortkey(p_bookmark_id)) as tree_sortkey) parents
		WHERE bm.tree_sortkey = parents.tree_sortkey
	) b
	WHERE b.bookmark_id = acs_objects.object_id
	AND acs_objects.security_inherit_p = 'f';

	RETURN v_private_p;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION bookmark__update_private_p (
       p_bookmark_id integer,
       p_private_p boolean
) RETURNS integer AS $$
DECLARE
	v_owner_id  bm_bookmarks.owner_id%TYPE;
	-- Not used... v_admin_p   bm_in_closed_p.closed_p%TYPE;

BEGIN

	IF p_private_p = FALSE THEN
	   -- Turn on security inheritance
	   UPDATE acs_objects SET security_inherit_p = TRUE WHERE object_id = p_bookmark_id;
	
	ELSE
		-- Private case
		-- turn off inheritance
		UPDATE acs_objects SET security_inherit_p = FALSE WHERE object_id = p_bookmark_id;

		-- Grant admin rights to the owner
		SELECT owner_id INTO v_owner_id FROM bm_bookmarks WHERE bookmark_id = p_bookmark_id;	
	
		PERFORM acs_permission__grant_permission (
		p_bookmark_id,
		v_owner_id,
		'admin');
	    
	END IF;
	RETURN 0;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION bookmark__initialize_in_closed_p (
       p_viewed_user_id integer,
       p_in_closed_p_id bigint,
       p_package_id integer
) RETURNS integer AS $$
DECLARE
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

