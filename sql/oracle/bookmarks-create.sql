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
	url_id			constraint bm_urls_url_id_fk
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
	meta_keywords 		varchar(4000),
	meta_description 	varchar(4000),
	last_checked_date 	date,
	-- the last time the site returned a "live" status
	last_live_date		date
);

begin
  acs_object_type.create_type ( 
    supertype     => 'acs_object', 
    object_type   => 'url', 
    pretty_name   => 'URL', 
    pretty_plural => 'URLs', 
    table_name    => 'BM_URLS', 
    id_column     => 'URL_ID' 
  );     
end;
/
show errors


create table bm_bookmarks (
	bookmark_id		constraint bm_bookmarks_bookmark_id_fk
				references acs_objects (object_id) on delete cascade
				constraint bm_bookmarks_bookmark_id_pk
				primary key,
	owner_id		integer 
				constraint bm_bookmarks_owner_id_nn
				not null 
				constraint bm_bookmarks_owner_id_fk
				references users(user_id),
	-- url_id may be null if the bookmark is a folder
	url_id			integer 
				constraint bm_bookmarks_url_id_fk
				references bm_urls,
	-- a person may rename any of his bookmarks so we keep a local title
	local_title 		varchar(500),
	-- this is 't' if the bookmark is a folder
	folder_p 		char(1) default 'f' 
				constraint bm_bookmarks_folder_p_ck
				check (folder_p in ('t','f')),
	-- null parent_id indicates this is a top level folder/bookmark
	parent_id 		integer 
				constraint bm_bookmarks_parent_id_fk
				references acs_objects (object_id),
	-- When the bookmark was last clicked on
	last_access_date	date
);


-- We use these index for sorting the bookmarks tree

-- DRB: Functional indexes are an Enterprise Edition feature, so this is disabled.  What should
-- we use?  I'm not sure at the moment because most of the queries seem to use UPPER not LOWER
-- on local title, at least in LIKE clauses!  Making this index fairly useless (besides it is
-- only useful if parent_id is included as a qualifier in such cases).
-- create index bm_bookmarks_local_title_idx on bm_bookmarks (parent_id, lower(local_title), bookmark_id);

create index bm_bookmarks_access_date_idx on bm_bookmarks (parent_id, last_access_date, bookmark_id);

-- For connect by queries
create index bm_bookmarks_idx1 on bm_bookmarks(bookmark_id, parent_id);
create index bm_bookmarks_idx2 on bm_bookmarks(parent_id, bookmark_id);


begin
  acs_object_type.create_type ( 
    supertype     => 'acs_object', 
    object_type   => 'bookmark', 
    pretty_name   => 'Bookmark', 
    pretty_plural => 'Bookmarks', 
    table_name    => 'BM_BOOKMARKS', 
    id_column     => 'BOOKMARK_ID',
    name_method   => 'bookmark.name'
  );     
end;
/
show errors


-- We need this table to keep track of which bookmarks are in a closed folder (they
-- are not to be displayed)
-- This has to be done on a per user (or per session) basis so we can not store
-- this information in the bm_bookmarks table (otherwise we would have problems when
-- two users view the same bookmarks concurently).
create table bm_in_closed_p (
       bookmark_id	    constraint bm_in_closed_p_bookmark_id_nn
			    not null
			    constraint bm_in_closed_p_bookmark_id_fk
			    references bm_bookmarks,			   
       in_closed_p_id	    integer 
			    constraint bm_in_closed_p_id_nn
			    not null, 
       in_closed_p	    char(1) default 't' 
			    constraint bm_in_closed_p_closed_p_ck
			    check (in_closed_p in ('t','f')),			    
       -- We might want to clean up old rows in this table since it could
       -- easily grow very large in big communities sharing bookmarks actively
       -- refers to whether a folder is open or closed
       closed_p		    char(1) default 'f' 
			    constraint bm_bookmarks_closed_p_ck
			    check (closed_p in ('t','f')),
       creation_date	    date,
       constraint bm_in_closed_p_pk
       primary key (bookmark_id, in_closed_p_id)
); 

comment on column bm_in_closed_p.in_closed_p_id is '
 This is the user_id for registered users and the session_id in sec_sessions
 for non-registered users.
';


create unique index bm_in_closed_p_idx on bm_in_closed_p (bookmark_id, in_closed_p_id, in_closed_p);


create or replace package url
as
    function new (
       url_id	 	in bm_urls.url_id%TYPE,
       url_title	in bm_urls.url_title%TYPE,
       host_url		in bm_urls.host_url%TYPE default null,
       complete_url	in bm_urls.complete_url%TYPE,
       meta_keywords	in bm_urls.meta_keywords%TYPE default null,
       meta_description in bm_urls.meta_description%TYPE default null,

       creation_user    in acs_objects.creation_user%TYPE default null, 
       creation_ip      in acs_objects.creation_ip%TYPE default null, 
       context_id       in acs_objects.context_id%TYPE default null        
    ) return bm_urls.url_id%TYPE;

    procedure del (
       url_id		in bm_urls.url_id%TYPE
    );

    function insert_or_update (
       url_title	in bm_urls.url_title%TYPE,
       host_url		in bm_urls.host_url%TYPE default null,
       complete_url	in bm_urls.complete_url%TYPE,
       meta_keywords	in bm_urls.meta_keywords%TYPE default null,
       meta_description in bm_urls.meta_description%TYPE default null,

       creation_user    in acs_objects.creation_user%TYPE default null, 
       creation_ip      in acs_objects.creation_ip%TYPE default null, 
       context_id       in acs_objects.context_id%TYPE default null        
    ) return bm_urls.url_id%TYPE;
end url;
/
show errors


create or replace package body url
as
    function new (
       url_id	 	in bm_urls.url_id%TYPE,
       url_title	in bm_urls.url_title%TYPE,
       host_url		in bm_urls.host_url%TYPE,
       complete_url	in bm_urls.complete_url%TYPE,
       meta_keywords	in bm_urls.meta_keywords%TYPE default null,
       meta_description in bm_urls.meta_description%TYPE default null,
       
       creation_user    in acs_objects.creation_user%TYPE default null, 
       creation_ip      in acs_objects.creation_ip%TYPE default null, 
       context_id       in acs_objects.context_id%TYPE default null        
    ) return bm_urls.url_id%TYPE
    is
       v_url_id integer;	
    begin
       v_url_id := acs_object.new (
          object_id     => url_id,       
          object_type   => 'url', 
          creation_date => sysdate, 
          creation_user => creation_user, 
          creation_ip   => creation_ip, 
          context_id    => context_id 
       );

       insert into bm_urls 
             (url_id, url_title, host_url, complete_url, meta_keywords, meta_description) 
          values 
	     (v_url_id, url_title, host_url, complete_url, meta_keywords, meta_description);
	     
       return v_url_id;     
    end new;

    procedure del (
       url_id		in bm_urls.url_id%TYPE
    )
    is
    begin
       acs_object.del(url.del.url_id);
    end del;

    function insert_or_update (
       url_title	in bm_urls.url_title%TYPE,
       host_url		in bm_urls.host_url%TYPE default null,
       complete_url	in bm_urls.complete_url%TYPE,
       meta_keywords	in bm_urls.meta_keywords%TYPE default null,
       meta_description in bm_urls.meta_description%TYPE default null,

       creation_user    in acs_objects.creation_user%TYPE default null, 
       creation_ip      in acs_objects.creation_ip%TYPE default null, 
       context_id       in acs_objects.context_id%TYPE default null        
    ) return bm_urls.url_id%TYPE
    is
	n_complete_urls integer;
	return_id integer;
	new_url_id integer;
    begin
	select count(*) into n_complete_urls 
	from bm_urls where bm_urls.complete_url = insert_or_update.complete_url;

	if n_complete_urls = 0 then

	   select acs_object_id_seq.nextval into new_url_id from dual;

	   return_id := url.new (
           url_id => new_url_id,
           url_title => insert_or_update.url_title,
	   host_url => insert_or_update.host_url,
	   complete_url => insert_or_update.complete_url,
           creation_user => insert_or_update.creation_user,
           creation_ip => insert_or_update.creation_ip
	   );
	   
	   return return_id;
	else
	    select url_id into return_id from bm_urls where bm_urls.complete_url= insert_or_update.complete_url;
	    return return_id;
	end if;

	
    end insert_or_update;

end url;
/
show errors


create or replace package bookmark
as
    function new (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE,
       owner_id		    in bm_bookmarks.owner_id%TYPE,
       url_id		    in bm_urls.url_id%TYPE default null,
       local_title	    in bm_bookmarks.local_title%TYPE default null,
       folder_p		    in bm_bookmarks.folder_p%TYPE default 'f',
       parent_id	    in bm_bookmarks.parent_id%TYPE,
       last_access_date	    in bm_bookmarks.last_access_date%TYPE default null,

       creation_user	    in acs_objects.creation_user%TYPE default null, 
       creation_ip	    in acs_objects.creation_ip%TYPE default null, 
       context_id	    in acs_objects.context_id%TYPE default null        
    ) return bm_bookmarks.bookmark_id%TYPE;

    procedure del (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE
    );


    function name (
       object_id	    in bm_bookmarks.bookmark_id%TYPE
    ) return bm_bookmarks.local_title%TYPE;

    function get_in_closed_p (
	     new_parent_id     in bm_bookmarks.bookmark_id%TYPE,
	     user_id	       in users.user_id%TYPE
    ) return bm_in_closed_p.in_closed_p%TYPE;

    procedure update_in_closed_p_one_user (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE,	     
       browsing_user_id     in bm_bookmarks.owner_id%TYPE
    );

    procedure update_in_closed_p_all_users (
	     bookmark_id       in bm_bookmarks.bookmark_id%TYPE,
	     new_parent_id     in bm_bookmarks.bookmark_id%TYPE
    );

    procedure toggle_open_close (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE,	     
       browsing_user_id     in bm_bookmarks.owner_id%TYPE
    );

    procedure toggle_open_close_all (
       browsing_user_id     in bm_bookmarks.owner_id%TYPE,
       closed_p		    in bm_in_closed_p.closed_p%TYPE default 'f',
       root_id		    in bm_bookmarks.parent_id%TYPE
    );
    
     function get_root_folder (
         package_id	     in apm_packages.package_id%TYPE,
 	user_id		     in users.user_id%TYPE
     ) return bm_bookmarks.bookmark_id%TYPE;


    function new_root_folder (
         package_id	     in apm_packages.package_id%TYPE,
 	user_id		     in users.user_id%TYPE	
     ) return bm_bookmarks.bookmark_id%TYPE;

    function private_p (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE	     
     ) return bm_in_closed_p.closed_p%TYPE;

     procedure update_private_p (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE,	     
       private_p		    in bm_in_closed_p.closed_p%TYPE
     );

     procedure initialize_in_closed_p (
 	viewed_user_id      in users.user_id%TYPE,
 	in_closed_p_id    in users.user_id%TYPE,
 	package_id	  in apm_packages.package_id%TYPE
     );

end bookmark;
/
show errors


create or replace package body bookmark 
as 
   function new ( 
	bookmark_id in bm_bookmarks.bookmark_id%TYPE, 
	owner_id in bm_bookmarks.owner_id%TYPE, 
	url_id in bm_urls.url_id%TYPE default null, 
	local_title in bm_bookmarks.local_title%TYPE default null,
	folder_p in bm_bookmarks.folder_p%TYPE default 'f', 
	parent_id in bm_bookmarks.parent_id%TYPE, 
        last_access_date	    in bm_bookmarks.last_access_date%TYPE default null,

       creation_user	    in acs_objects.creation_user%TYPE default null, 
       creation_ip	    in acs_objects.creation_ip%TYPE default null, 
       context_id	    in acs_objects.context_id%TYPE default null        
     ) return bm_bookmarks.bookmark_id%TYPE
    is
	v_bookmark_id integer;
	v_last_access_date bm_bookmarks.last_access_date%TYPE;
	v_in_closed_p bm_in_closed_p.in_closed_p%TYPE;

	cursor c_viewing_in_closed_p_ids
	is
	select unique in_closed_p_id 
	from bm_in_closed_p 
	where bookmark_id = (select parent_id from bm_bookmarks 
			     where bookmark_id = new.bookmark_id); 
    begin
	v_bookmark_id := acs_object.new (
	   object_id     => bookmark_id,
           object_type   => 'bookmark', 
           creation_date => sysdate, 
           creation_user => creation_user, 
           creation_ip   => creation_ip, 
           context_id    => parent_id   
	);
		
	if last_access_date is null then
	   select sysdate into v_last_access_date from dual;
	else
	   v_last_access_date := last_access_date;   
	end if;

	insert into bm_bookmarks
	      (bookmark_id, owner_id, url_id, local_title, 
	      folder_p, parent_id, last_access_date)
	   values
	      (v_bookmark_id, owner_id, url_id, local_title, 
	      folder_p, parent_id, v_last_access_date); 

	
	-- Now we have to set the in_closed_p information for this
	-- bookmark for all users that are viewing this bookmark tree
	for one_row in c_viewing_in_closed_p_ids
	loop
	    -- For each user or session record the in_closed_p status of
	    -- the bookmark
	    select bookmark.get_in_closed_p(parent_id, one_row.in_closed_p_id)
		   into v_in_closed_p from dual;

	    insert into bm_in_closed_p (bookmark_id, in_closed_p_id, in_closed_p, creation_date)
			values (v_bookmark_id, one_row.in_closed_p_id, v_in_closed_p, sysdate); 
	    
	end loop;

	      
	return v_bookmark_id;
    end new;


    -- The reason this procedure is so terribly complex is that I wanted to enable
    -- deleting of non empty folders. The problem is that we have to delete the bookmarks
    -- in the right order not to violate any referential constraints.
    procedure del (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE
    )
    is
    
	-- This is the outer cursor that starts with the leaf bookmarks under the folder
	-- to be deleted and walks up to the folder to be deleted. 
	cursor c_bookmark_id_tree
	is
	select bookmark_id
	from bm_bookmarks
	where bookmark_id not in (select bookmark_id from bm_bookmarks
			          start with bookmark_id = (select parent_id from bm_bookmarks
							   where bookmark_id = bookmark.del.bookmark_id)
			          connect by prior parent_id = bookmark_id)
	start with bookmark_id in (select bookmark_id
			       from bm_bookmarks bm_outer where not exists
			        (select 1 from bm_bookmarks bm_inner where 
				 bm_outer.bookmark_id = bm_inner.parent_id)
				 intersect
				 select bookmark_id from bm_bookmarks 
				 start with bookmark_id = bookmark.del.bookmark_id
				 connect by prior bookmark_id = parent_id 
		              )
	connect by prior parent_id = bookmark_id;


	-- To avoid violating referential constraints we need also (at least no smarter way to 
	-- do this occured to me) to delete all bookmarks on the level of the outer cursor
	-- that lie under the folder to be deleted. 
	cursor c_bookmark_id_one_level (tree_id in integer)
	is
	select bookmark_id
	from bm_bookmarks bm_outer
	where parent_id = (select parent_id from bm_bookmarks where bookmark_id = tree_id)
	and not exists (select 1 from bm_bookmarks where parent_id = bm_outer.bookmark_id)
	and bm_outer.bookmark_id in (select bookmark_id from bm_bookmarks 
				    start with bookmark_id = bookmark.del.bookmark_id
				    connect by prior bookmark_id = parent_id);

    begin

 	for tree_bookmark_id in c_bookmark_id_tree
 	loop

 	    for one_level_bookmark_id in c_bookmark_id_one_level(tree_bookmark_id.bookmark_id)
 	    loop
		delete from acs_permissions where object_id = one_level_bookmark_id.bookmark_id;
		delete from bm_in_closed_p where bookmark_id = one_level_bookmark_id.bookmark_id;
		delete from bm_bookmarks where bookmark_id = one_level_bookmark_id.bookmark_id;
 		acs_object.del(one_level_bookmark_id.bookmark_id);
 	    end loop;
 	end loop;

    end del;

    function name (
       object_id	    in bm_bookmarks.bookmark_id%TYPE
    ) return bm_bookmarks.local_title%TYPE
    is
	v_name	bm_bookmarks.local_title%TYPE;
    begin
	select local_title into v_name
	from bm_bookmarks
	     where bookmark_id = name.object_id;

	return v_name;
    end name;

    function get_in_closed_p (
	     new_parent_id     in bm_bookmarks.bookmark_id%TYPE,
	     user_id	       in users.user_id%TYPE
    ) return bm_in_closed_p.in_closed_p%TYPE
    is
	return_value bm_in_closed_p.in_closed_p%TYPE;
    begin
	select decode(count(*), 0, 'f', 't') into return_value
	from (select bookmark_id from bm_bookmarks
	      connect by prior parent_id = bookmark_id
	      start with bookmark_id = new_parent_id) bm,
	      bm_in_closed_p bic
	where bm.bookmark_id = bic.bookmark_id (+)
	and bic.closed_p = 't'
	and bic.in_closed_p_id = get_in_closed_p.user_id;

	return return_value;
    end get_in_closed_p;

    procedure update_in_closed_p_one_user (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE,	     
       browsing_user_id     in bm_bookmarks.owner_id%TYPE
    )
    is
    begin
	-- Update the in_closed_p flag of bookmarks and folders that lie under
	-- the toggled folder in the tree for one particular user/session.

	-- First set all in_closed_p flags to 'f' ...
	update bm_in_closed_p set in_closed_p = 'f' 
	       where bookmark_id in (select bookmark_id from bm_bookmarks
		   start with bookmark_id = update_in_closed_p_one_user.bookmark_id
		   connect by prior bookmark_id = parent_id)
	       and in_closed_p_id = update_in_closed_p_one_user.browsing_user_id;

        -- then set all in_closed_p flags to 't' that lie under a closed folder
	update bm_in_closed_p set in_closed_p = 't' 
	       where bookmark_id in (select bookmark_id from bm_bookmarks
		   start with parent_id in (select bm.bookmark_id from bm_bookmarks bm, 
					                            bm_in_closed_p bip
			                    where bm.bookmark_id = bip.bookmark_id
					    and bm.folder_p = 't' 
					    and bip.closed_p = 't'
					    and bip.in_closed_p_id = 
						update_in_closed_p_one_user.browsing_user_id )
		   connect by prior bookmark_id = parent_id
			   intersect
	           select bookmark_id from bm_bookmarks
			  start with bookmark_id = update_in_closed_p_one_user.bookmark_id
			  connect by prior bookmark_id = parent_id)
	       and in_closed_p_id = update_in_closed_p_one_user.browsing_user_id;

    end update_in_closed_p_one_user;	      

    procedure update_in_closed_p_all_users (
	     bookmark_id       in bm_bookmarks.bookmark_id%TYPE,
	     new_parent_id     in bm_bookmarks.bookmark_id%TYPE
    )
    is
    -- We need a cursor to loop over all users viewing the tree
    	cursor c_viewing_in_closed_p_ids
	is
	select unique in_closed_p_id 
	from bm_in_closed_p 
	where bookmark_id = (select bookmark_id from bm_bookmarks 
			     where bookmark_id = update_in_closed_p_all_users.bookmark_id); 

    begin
	for one_row in c_viewing_in_closed_p_ids
	loop	
	    -- Update the in_closed_p status for this user/session for all bookmarks
	    -- under the folder
	    update_in_closed_p_one_user (bookmark_id, one_row.in_closed_p_id);
	end loop;
	
    end update_in_closed_p_all_users;

    procedure toggle_open_close (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE,	     
       browsing_user_id     in bm_bookmarks.owner_id%TYPE
    )
    is
    begin

	-- Toggle the closed_p flag
	update bm_in_closed_p set closed_p = (select decode(closed_p, 't', 'f', 't')
	       from bm_in_closed_p where bookmark_id = toggle_open_close.bookmark_id
	                           and in_closed_p_id = toggle_open_close.browsing_user_id)
	       where bookmark_id = bookmark.toggle_open_close.bookmark_id
	       and in_closed_p_id = toggle_open_close.browsing_user_id;

	-- Now update the in_closed_p status for this user for all bookmarks under
	-- the toggled folder
	update_in_closed_p_one_user (bookmark_id, browsing_user_id);
	
    end toggle_open_close;

    procedure toggle_open_close_all (
       browsing_user_id     in bm_bookmarks.owner_id%TYPE,
       closed_p		    in bm_in_closed_p.closed_p%TYPE default 'f',
       root_id		    in bm_bookmarks.parent_id%TYPE
    )
    is
    begin
	-- Change the value of closed_p for all folders belonging to the
	-- user (except the root folder)
	update bm_in_closed_p bm_outer set closed_p = bookmark.toggle_open_close_all.closed_p
	       where bookmark_id in (select bookmark_id from bm_bookmarks 
				     start with parent_id = toggle_open_close_all.root_id 
				     connect by prior bookmark_id = parent_id);

	-- Update the value of in_closed_p for all bookmarks belonging to 
	-- this user. We close/open all bookmarks except the top level ones.
	update bm_in_closed_p set in_closed_p = bookmark.toggle_open_close_all.closed_p
	       where bookmark_id in (select bookmark_id from bm_bookmarks 
		   start with parent_id in (select bookmark_id from bm_bookmarks 
			                   where parent_id = toggle_open_close_all.root_id) 
		   connect by prior bookmark_id = parent_id)
	       and in_closed_p_id = toggle_open_close_all.browsing_user_id;	 	

    end toggle_open_close_all;


     function get_root_folder (
         package_id	     in apm_packages.package_id%TYPE,
 	user_id		     in users.user_id%TYPE
     ) return bm_bookmarks.bookmark_id%TYPE
    is
	v_folder_id	bm_bookmarks.bookmark_id%TYPE;
	v_count		integer;    
    begin
	select count(*) into v_count 
	from bm_bookmarks
	where parent_id = get_root_folder.package_id
	and   owner_id = get_root_folder.user_id;

	if v_count > 0 then
	    select bookmark_id into v_folder_id 
	    from bm_bookmarks
	    where parent_id = get_root_folder.package_id
	    and   owner_id = get_root_folder.user_id;
	else
	    -- must be a new instance.  Gotta create a new root folder
	    v_folder_id := new_root_folder(package_id, user_id);
	end if;

	return v_folder_id;
	    
    end get_root_folder;

    function new_root_folder (
         package_id	     in apm_packages.package_id%TYPE,
 	user_id		     in users.user_id%TYPE	
     ) return bm_bookmarks.bookmark_id%TYPE
    is
	v_folder_id	bm_bookmarks.bookmark_id%TYPE;
	v_bookmark_id   bm_bookmarks.bookmark_id%TYPE;
	v_email		parties.email%TYPE;
    begin

	select acs_object_id_seq.nextval into v_bookmark_id
	       from dual;

	select email into v_email 
	       from parties where party_id = new_root_folder.user_id;

	v_folder_id := bookmark.new (
       bookmark_id => v_bookmark_id,
       owner_id    => new_root_folder.user_id,
       folder_p => 't',
       local_title => ' Bookmarks Root Folder of ' || v_email,
       parent_id   => new_root_folder.package_id
       );
    
        -- set up default permissions
	-- The owner may administer the bookmarks
	-- Any other permissions will be inherited from the next higher
	-- package instance in the site hierarchy
	acs_permission.grant_permission (
            object_id => v_folder_id,
            grantee_id => new_root_folder.user_id,
            privilege => 'admin'
        );

	return v_folder_id;

    end new_root_folder;

    function private_p (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE	     
     ) return bm_in_closed_p.closed_p%TYPE
     is
	v_private_p  bm_in_closed_p.closed_p%TYPE;
     begin
	select decode(count(*), 0, 'f', 't') into v_private_p
	       from acs_objects, (select bookmark_id from bm_bookmarks 
			          start with bookmark_id = private_p.bookmark_id
				  connect by prior parent_id = bookmark_id) b
	       where b.bookmark_id = acs_objects.object_id
	       and acs_objects.security_inherit_p = 'f';

	return v_private_p;
     end private_p;

     procedure update_private_p (
       bookmark_id	    in bm_bookmarks.bookmark_id%TYPE,	     
       private_p		    in bm_in_closed_p.closed_p%TYPE
     )
     is
	v_owner_id  bm_bookmarks.owner_id%TYPE;
	v_admin_p   bm_in_closed_p.closed_p%TYPE;
     begin

	if private_p = 'f' then
	   -- Turn on security inheritance
	   update acs_objects set security_inherit_p = 't' where object_id = bookmark_id;

	else
	    -- Private case
	    -- turn off inheritance
	    update acs_objects set security_inherit_p = 'f' where object_id = bookmark_id;

	    -- Grant admin rights to the owner
	    select owner_id into v_owner_id from bm_bookmarks where bookmark_id = update_private_p.bookmark_id;	
	    acs_permission.grant_permission(bookmark_id, v_owner_id, 'admin');	    
	    
	end if;

     end update_private_p;


     procedure initialize_in_closed_p (
 	viewed_user_id      in users.user_id%TYPE,
 	in_closed_p_id    in users.user_id%TYPE,
 	package_id	  in apm_packages.package_id%TYPE
     )
     is
	v_count_in_closed_p integer;
	v_count_bookmarks integer;

	cursor c_bookmark_ids( viewed_user_id in integer, in_closed_p_id in integer)
	is
	select bookmark_id
	   from bm_bookmarks
	   where owner_id = c_bookmark_ids.viewed_user_id
	   and bookmark_id not in (select bookmark_id from bm_in_closed_p
				        where in_closed_p_id = c_bookmark_ids.in_closed_p_id);	
     begin
	   for v_bookmark_id in c_bookmark_ids(initialize_in_closed_p.viewed_user_id, 
					    initialize_in_closed_p.in_closed_p_id)
	   loop
	       insert into bm_in_closed_p (bookmark_id, in_closed_p_id, in_closed_p, creation_date)
		   values (v_bookmark_id.bookmark_id, initialize_in_closed_p.in_closed_p_id, 'f', sysdate);
	   end loop;

     end initialize_in_closed_p;
end bookmark;
/
show errors
