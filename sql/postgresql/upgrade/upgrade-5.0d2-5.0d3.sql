-- Fixing usage of sequences 
-- @author Victor Guerra (vguerra@wu.ac.at)
-- @creation-date 2013-09-06

CREATE OR REPLACE FUNCTION url__insert_or_update (varchar,varchar,varchar,text,text,integer,varchar,integer)
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

CREATE OR REPLACE FUNCTION bookmark__new_root_folder (integer, integer)
RETURNS integer AS '
DECLARE
        p_package_id ALIAS FOR $1;	-- in apm_packages.package_id%TYPE,
 	p_user_id ALIAS FOR $2;		-- in users.user_id%TYPE
	v_folder_id	bm_bookmarks.bookmark_id%TYPE;
	v_bookmark_id   bm_bookmarks.bookmark_id%TYPE;
	v_email		parties.email%TYPE;
	v_local_title	bm_bookmarks.local_title%TYPE;

BEGIN
	SELECT nextval(''t_acs_object_id_seq'') INTO v_bookmark_id FROM dual;
        
	SELECT email INTO v_email 
	FROM parties where party_id = p_user_id;

	v_local_title := '' Bookmarks Root Folder of '' || v_email;
	v_folder_id := bookmark__new (
		    v_bookmark_id,
		    p_user_id,
		    null,
		    v_local_title,
		    ''t'',
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
		''admin'');
	
		-- object_id => v_folder_id,
		-- grantee_id => new_root_folder.user_id,
		-- privilege => admin

	RETURN v_folder_id;

END;
' LANGUAGE 'plpgsql';

