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
	last_checked_date 	timestamp,
	-- the last time the site returned a "live" status
	last_live_date		timestamp
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
	last_access_date	timestamp,
        tree_sortkey            varchar(4000)
);


-- We use these index for sorting the bookmarks tree
-- KDK: Functional indices in postgres presently must be only single column indices
--Change create index bm_bookmarks_local_title_idx on bm_bookmarks (parent_id, lower(local_title), bookmark_id); to:

create index bm_bookmarks_local_title_idx on bm_bookmarks (lower(local_title));

-- KDK: The other columns from the original Oracle index are handled by bm_bookmarks_access_date_idx (for parent_id), and the primary key (for bookmark_id)

create index bm_bookmarks_access_date_idx on bm_bookmarks (parent_id, last_access_date, bookmark_id);


-- For connect by queries
create index bm_bookmarks_idx1 on bm_bookmarks(bookmark_id, parent_id);
create index bm_bookmarks_idx2 on bm_bookmarks(parent_id, bookmark_id);

create function bm_bookmarks_insert_tr () returns opaque as '
declare
        v_parent_sk     varchar;
        max_key         varchar;
begin
        if new.parent_id is null then 
            select max(tree_sortkey) into max_key 
              from bm_bookmarks 
             where parent_id is null;

            v_parent_sk := '''';
        else 
            select max(tree_sortkey) into max_key 
              from bm_bookmarks 
             where parent_id = new.parent_id;

            select coalesce(max(tree_sortkey),'''') into v_parent_sk 
              from bm_bookmarks 
             where object_id = new.parent_id;
        end if;


        new.tree_sortkey := v_parent_sk || ''/'' || tree_next_key(max_key);

        return new;

end;' language 'plpgsql';


create trigger bm_bookmarks_insert_tr before insert 
on bm_bookmarks for each row 
execute procedure bm_bookmarks_insert_tr ();

create function bm_bookmarks_update_tr () returns opaque as '
declare
        v_parent_sk     varchar;
        max_key         varchar;
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
                      where tree_sortkey like new.tree_sortkey || ''%''
                   order by tree_sortkey
        LOOP
            if clr_keys_p then
               update bm_bookmarks set tree_sortkey = null
               where tree_sortkey like new.tree_sortkey || ''%'';
               clr_keys_p := ''f'';
            end if;
            
            select parent_id into ctx_id
              from bm_bookmarks 
             where bookmark_id = v_rec.bookmark_id;

            if ctx_id is null then 
                select max(tree_sortkey) into max_key
                  from bm_bookmarks 
                 where parent_id is null;

                v_parent_sk := '''';
            else 
                select max(tree_sortkey) into max_key
                  from bm_bookmarks 
                 where parent_id = ctx_id;

                select coalesce(max(tree_sortkey),'''') into v_parent_sk 
                  from bm_bookmarks 
                 where bookmark_id = ctx_id;
            end if;

            update bm_bookmarks 
               set tree_sortkey = v_parent_sk || ''/'' || tree_next_key(max_key)
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
       in_closed_p_id	    integer 
			    constraint bm_in_closed_p_id_nn
			    not null, 
       in_closed_p	    boolean default 't', 
			    
       -- We might want to clean up old rows in this table since it could
       -- easily grow very large in big communities sharing bookmarks actively
       -- refers to whether a folder is open or closed
       closed_p		    boolean default 'f', 
       creation_date	    timestamp,
       constraint bm_in_closed_p_pk
       primary key (bookmark_id, in_closed_p_id)
); 


comment on column bm_in_closed_p.in_closed_p_id is '
 This is the user_id for registered users and the session_id in sec_sessions
 for non-registered users.
';


create unique index bm_in_closed_p_idx on bm_in_closed_p (bookmark_id, in_closed_p_id, in_closed_p);

--KDK: here!

CREATE FUNCTION url__new(integer,varchar,varchar,varchar,text,text,integer,varchar,integer)
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

CREATE FUNCTION url__delete(integer)
RETURNS integer AS '
DECLARE
       p_url_id ALIAS FOR $1;	
BEGIN
   PERFORM acs_object__delete(p_url_id);
	     
   return 0;     

END;
' LANGUAGE 'plpgsql';

CREATE FUNCTION url__insert_or_update(varchar,varchar,varchar,text,text,integer,varchar,integer)
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

	   select acs_object_id_seq.nextval into v_new_url_id from dual;

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

END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__new(varchar,varchar,varchar,text,text,integer,varchar,integer)
RETURNS integer AS '
DECLARE
	p_bookmark_id ALIAS FOR $1;		-- in bm_bookmarks.bookmark_id%TYPE, 
	p_owner_id ALIAS FOR $2;		-- in bm_bookmarks.owner_id%TYPE, 
	p_url_id in ALIAS FOR $3;		-- bm_urls.url_id%TYPE default null, 
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
		      p_context_id
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
			     where bookmark_id = v_bookmark_id); 
	LOOP
	    -- For each user or session record the in_closed_p status of
	    -- the bookmark
	    select bookmark__get_in_closed_p(parent_id, c_viewing_in_closed_p_ids.in_closed_p_id)
		   into v_in_closed_p;

	    insert into bm_in_closed_p (bookmark_id, in_closed_p_id, in_closed_p, creation_date)
			values (v_bookmark_id, c_viewing_in_closed_p_ids.in_closed_p_id, v_in_closed_p, now()); 
	    
	END LOOP;
	
	RETURN v_bookmark_id;      

END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__delete(integer)
RETURNS integer AS '
DECLARE
	p_bookmark_id ALIAS FOR $1;	-- in bm_bookmarks.bookmark_id%TYPE,
	c_bookmark_id_tree RECORD;
	c_bookmark_id_one_level RECORD;
BEGIN

 	FOR c_bookmark_id_tree IN 
	    select bookmark_id
	    from bm_bookmarks
	    where bookmark_id not in 
		  (
		  select bookmark_id from bm_bookmarks
		  where tree_sortkey like 
			(
			select tree_sortkey || ''%''
			from bm_bookmarks 
			where bookmark_id = p_bookmark_id
			)
		  order by tree_sortkey
		  )
	    where tree_sortkey like
		  (
		  select tree_sortkey || ''%''
		  from bm_bookmarks 
		  where bookmark_id in 
		  (
		  select bookmark_id
		  from bm_bookmarks bm_outer where not exists
		       (
		       select 1 from bm_bookmarks bm_inner where 
		       bm_outer.bookmark_id = bm_inner.parent_id
		       )
		  intersect
		  select bookmark_id from bm_bookmarks
		  where tree_sortkey like
			(
			select tree_sortkey || ''%''
			from bm_bookmarks
			where bookmark_id = p_bookmark_id
			)
		  order by tree_sortkey
		  )
            order by tree_sortkey;
 	LOOP
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
		select bookmark_id from bm_bookmarks 
		where tree_sortkey like 
		(
			select tree_sortkey || ''%'' from bm_bookmarks
			where bookmark_id = p_bookmark_id
		)
		order by tree_sortkey
	    );

 	    for one_level_bookmark_id in c_bookmark_id_one_level(tree_bookmark_id.bookmark_id)
 	    LOOP
		delete from acs_permissions where object_id = c_bookmark_id_one_level.bookmark_id;
		delete from bm_in_closed_p where bookmark_id = c_bookmark_id_one_level.bookmark_id;
		delete from bm_bookmarks where bookmark_id = c_bookmark_id_one_level.bookmark_id;
 		acs_object__delete(c_bookmark_id_one_level.bookmark_id);
 	    END LOOP;
 	END LOOP;

END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__name(integer)
RETURNS integer AS '
DECLARE
	p_object_id ALIAS FOR $1;	-- in bm_bookmarks.bookmark_id%TYPE,
	v_name	bm_bookmarks.local_title%TYPE;
BEGIN
	select local_title into v_name
	from bm_bookmarks
	     where bookmark_id = p_object_id;

	return v_name;
END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__get_in_closed_p(integer,integer)
RETURNS integer AS '
DECLARE
	p_new_parent_id ALIAS FOR $1;	-- in bm_bookmarks.bookmark_id%TYPE,
	p_user_id	ALIAS FOR $2;	-- in users.user_id%TYPE	
	v_return_value bm_in_closed_p.in_closed_p%TYPE;
	v_count integer;
BEGIN

	select (case when count(*) = 0 then ''f'' else ''t'' end) into
	v_return_value from 
	(
	     select bookmark_id from bm_bookmarks
	     where tree_sortkey like 
	     (
		   select tree_sortkey || ''%''
		   from bm_bookmarks
		   where bookmark_id = p_new_parent_id
	     )
	     
	     bm left join bm_in_closed_p bic on (bm.bookmark_id = bic.bookmark_id)
	     and bic.closed_p = ''t''
	     and bic.in_closed_p_id = p_user_id
	     order by tree_sortkey
	)
	return v_return_value;
END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__update_in_closed_p_one_user(integer, integer)
RETURNS integer AS '
DECLARE
       p_bookmark_id ALIAS FOR $1;	-- in bm_bookmarks.bookmark_id%TYPE,	     
       p_browsing_user_id ALIAS FOR $2;	-- in bm_bookmarks.owner_id%TYPE

BEGIN
	-- Update the in_closed_p flag of bookmarks and folders that lie under
	-- the toggled folder in the tree for one particular user/session.

	-- First set all in_closed_p flags to f ...
	UPDATE bm_in_closed_p SET in_closed_p = ''f'' 
	WHERE bookmark_id IN 
	      (
	      select bookmark_id from bm_bookmarks
	      where tree_sortkey like
		    (
		    select tree_sortkey || ''%''
		    from bm_bookmarks 
		    where bookmark_id = p_bookmark_id
		    )
	      order by tree_sortkey
	      )
	AND in_closed_p_id = p_browsing_user_id;

        -- then set all in_closed_p flags to t that lie under a closed folder
	UPDATE bm_in_closed_p set in_closed_p = ''t'' 
	WHERE bookmark_id IN 
	      (
	      select bookmark_id from bm_bookmarks
	      where tree_sortkey like
		    (
		    select tree_sortkey || ''%''
		    from bm_bookmarks 
		    where parent_id in 
			  (
			  select bm.bookmark_id from 
			  bm_bookmarks bm, bm_in_closed_p bip
			  where bm.bookmark_id = bip.bookmark_id
			  and bm.folder_p = ''t'' 
			  and bip.closed_p = ''t''
			  and bip.in_closed_p_id = p_browsing_user_id
			  )
		    )
	      order by tree_sortkey
	      INTERSECT
	      select bookmark_id from bm_bookmarks
	      where tree_sortkey like
		    (
		    select tree_sortkey || ''%''
		    from bm_bookmarks 
		    where bookmark_id = p_bookmark_id 
		    )
	      order by tree_sortkey
	      )
	AND in_closed_p_id = p_browsing_user_id;

END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__update_in_closed_p_all_users(integer, integer)
RETURNS integer AS '
DECLARE
	p_bookmark_id ALIAS FOR $1;	-- in bm_bookmarks.bookmark_id%TYPE,
	p_new_parent_id ALIAS FOR $2;	-- in bm_bookmarks.bookmark_id%TYPE
	c_viewing_in_closed_p_ids RECORD;

BEGIN
	FOR c_viewing_in_closed_p_ids IN
	select unique in_closed_p_id 
	from bm_in_closed_p 
	where bookmark_id = (select bookmark_id from bm_bookmarks 
			     where bookmark_id = p_bookmark_id) 
	LOOP	
	    -- Update the in_closed_p status for this user/session for all bookmarks
	    -- under the folder
	    update_in_closed_p_one_user (p_bookmark_id, c_viewing_in_closed_p_ids.in_closed_p_id);
	END LOOP;

END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__toggle_open_close (integer, integer)
RETURNS integer AS '
DECLARE
	p_bookmark_id ALIAS FOR $1;		-- in bm_bookmarks.bookmark_id%TYPE,	     
	p_browsing_user_id ALIAS FOR $2;	-- in bm_bookmarks.owner_id%TYPE

BEGIN
	-- Toggle the closed_p flag
	UPDATE bm_in_closed_p SET closed_p = 
	       (
	       SELECT CASE WHEN closed_p = ''t'' THEN ''f'' ELSE ''t''
	       FROM bm_in_closed_p 
	       WHERE bookmark_id = p_bookmark_id
	       AND in_closed_p_id = p_browsing_user_id
	       )
	WHERE bookmark_id = p_bookmark_id
	AND in_closed_p_id = p_browsing_user_id;

	-- Now update the in_closed_p status for this user for all bookmarks under
	-- the toggled folder
	update_in_closed_p_one_user (p_bookmark_id, p_browsing_user_id);

END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__toggle_open_close_all (integer, boolean, integer)
RETURNS integer AS '
DECLARE
	p_browsing_user_id ALIAS FOR $1;	-- in bm_bookmarks.owner_id%TYPE,
	p_closed_p ALIAS FOR $2;		-- in bm_in_closed_p.closed_p%TYPE default f,
	p_root_id ALIAS FOR $3;			-- in bm_bookmarks.parent_id%TYPE

BEGIN
	-- Change the value of closed_p for all folders belonging to the
	-- user (except the root folder)
	UPDATE bm_in_closed_p bm_outer SET closed_p = p_closed_p
	WHERE bookmark_id IN 
	(
		SELECT bookmark_id FROM bm_bookmarks
		WHERE tree_sortkey like
		    (
		    SELECT tree_sortkey || ''%''
		    FROM bm_bookmarks 
		    WHERE parent_id = p_root_id
		    )
		ORDER BY tree_sortkey
	); 

	-- Update the value of in_closed_p for all bookmarks belonging to 
	-- this user. We close/open all bookmarks except the top level ones.
	UPDATE bm_in_closed_p SET in_closed_p = p_closed_p
	WHERE bookmark_id IN 
	(
		SELECT bookmark_id FROM bm_bookmarks 
		WHERE tree_sortkey like
		(
		    SELECT tree_sortkey || ''%''
		    FROM bm_bookmarks 
		    WHERE parent_id in 
		    (
			SELECT bookmark_id FROM bm_bookmarks 
			WHERE parent_id = p_root_id
		    )
		ORDER BY tree_sortkey
		) 
	AND in_closed_p_id = p_browsing_user_id;	 	


END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__new_root_folder (integer, integer)
RETURNS integer AS '
DECLARE
        p_package_id ALIAS FOR $1;	-- in apm_packages.package_id%TYPE,
 	p_user_id ALIAS FOR $2;		-- in users.user_id%TYPE
	v_folder_id	bm_bookmarks.bookmark_id%TYPE;
	v_bookmark_id   bm_bookmarks.bookmark_id%TYPE;
	v_email		parties.email%TYPE;

BEGIN
	SELECT acs_object_id_seq.nextval INTO v_bookmark_id FROM dual;

	SELECT email INTO v_email 
	FROM parties where party_id = p_user_id;

	v_folder_id := bookmark__new (
		    v_bookmark_id,
		    p_user_id,
		    null,
		    '' Bookmarks Root Folder of '' || v_email,
		    ''t'',
		    p_package_id,
		    null,
		    null,
		    null,
		    null);

		    -- bookmark_id => v_bookmark_id,
		    -- owner_id    => p_user_id,
		    -- folder_p => ''t'',
		    -- local_title => '' Bookmarks Root Folder of '' || v_email,
		    -- parent_id   => new_root_folder.package_id
    
        -- set up default permissions
	-- The owner may administer the bookmarks
	-- Any other permissions will be inherited from the next higher
	-- package instance in the site hierarchy
	PERFORM acs_permission__grant_permission (
		v_folder_id,
		p_user_id,
		''admin'');
	
		-- object_id => v_folder_id,
		-- grantee_id => new_root_folder.user_id,
		-- privilege => ''admin''

	RETURN v_folder_id;

END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__get_root_folder (integer, integer)
RETURNS integer AS '
DECLARE
        p_package_id ALIAS FOR $1;	-- in apm_packages.package_id%TYPE,
 	p_user_id ALIAS FOR $2;		-- in users.user_id%TYPE
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
	    v_folder_id := new_root_folder(package_id, user_id);
	END IF;

	RETURN v_folder_id;


END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__private_p (integer)
RETURNS boolean AS '
DECLARE
	p_bookmark_id ALIAS FOR $1;	-- in bm_bookmarks.bookmark_id%TYPE	     
	v_private_p  bm_in_closed_p.closed_p%TYPE;

BEGIN

	SELECT CASE WHEN count(*)=0 THEN ''f'' ELSE ''t'' END INTO v_private_p
	FROM acs_objects, 
	(
		SELECT bookmark_id FROM bm_bookmarks
		WHERE tree_sortkey like
		    (
		    SELECT tree_sortkey || ''%''
		    FROM bm_bookmarks 
		    WHERE bookmark_id = p_bookmark_id
		    )
		ORDER BY tree_sortkey
	) b
	WHERE b.bookmark_id = acs_objects.object_id
	AND acs_objects.security_inherit_p = ''f'';

	RETURN v_private_p;

END;
' LANGUAGE 'plpgsql';


CREATE FUNCTION bookmark__update_private_p (integer, boolean)
RETURNS integer AS '
DECLARE
	p_bookmark_id ALIAS FOR $1;	-- in bm_bookmarks.bookmark_id%TYPE,	     
	p_private_p ALIAS FOR $2;	-- in bm_in_closed_p.closed_p%TYPE
	v_owner_id  bm_bookmarks.owner_id%TYPE;
	-- Not used... v_admin_p   bm_in_closed_p.closed_p%TYPE;

BEGIN

	IF p_private_p = ''f'' THEN
	   -- Turn on security inheritance
	   UPDATE acs_objects SET security_inherit_p = ''t'' WHERE object_id = p_bookmark_id;
	
	ELSE
		-- Private case
		-- turn off inheritance
		UPDATE acs_objects SET security_inherit_p = ''f'' WHERE object_id = p_bookmark_id;

		-- Grant admin rights to the owner
		SELECT owner_id INTO v_owner_id FROM bm_bookmarks WHERE bookmark_id = p_bookmark_id;	
	
		PERFORM acs_permission__grant_permission (
		p_bookmark_id,
		v_owner_id,
		''admin'');
	    
	END IF;


END;
' LANGUAGE 'plpgsql';

CREATE FUNCTION bookmark__initialize_in_closed_p (integer, integer)
RETURNS integer AS '
DECLARE
 	p_viewed_user_id ALIAS FOR $1;	-- in users.user_id%TYPE,	
 	p_in_closed_p_id ALIAS FOR $2;	-- in users.user_id%TYPE	
	v_count_in_closed_p integer;
	v_count_bookmarks integer;

BEGIN

	   FOR c_bookmark_ids IN
	       SELECT bookmark_id FROM bm_bookmarks
	       WHERE owner_id = p_viewed_user_id
	       AND bookmark_id NOT IN 
	       (
		SELECT bookmark_id FROM bm_in_closed_p
		WHERE in_closed_p_id = p_in_closed_p_id
	       )
	   LOOP
	       INSERT INTO bm_in_closed_p (bookmark_id, in_closed_p_id, in_closed_p, creation_date)
	       VALUES (c_bookmark_ids.bookmark_id, p_in_closed_p_id, ''f'', now());
	   END LOOP;


END;
' LANGUAGE 'plpgsql';


