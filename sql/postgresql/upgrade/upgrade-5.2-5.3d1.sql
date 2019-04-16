CREATE OR REPLACE FUNCTION bookmark__name (
       p_object_id integer
) RETURNS varchar AS $$
DECLARE
    v_name bm_bookmarks.local_title%TYPE;
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
       p_browsing_user_id bigint
) RETURNS integer AS $$
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

CREATE OR REPLACE FUNCTION bookmark__new_root_folder (
       p_package_id integer,
       p_user_id integer
) RETURNS integer AS $$
DECLARE
    v_folder_id    bm_bookmarks.bookmark_id%TYPE;
    v_bookmark_id   bm_bookmarks.bookmark_id%TYPE;
    v_email        parties.email%TYPE;
    v_local_title    bm_bookmarks.local_title%TYPE;

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
    v_folder_id    bm_bookmarks.bookmark_id%TYPE;
    v_count        integer;

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
