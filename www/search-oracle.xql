<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="bookmark_search_user">      
      <querytext>
      
    select   bookmark_id, 
             complete_url,
             nvl(local_title, url_title) as title, 
             meta_keywords, 
             meta_description
    from     (select bookmark_id, url_id, local_title, folder_p, owner_id 
              from bm_bookmarks start with bookmark_id = :root_folder_id 
              connect by prior bookmark_id = parent_id) b, 
             bm_urls
    where    owner_id = :browsing_user_id 
    and      folder_p = 'f'
    and      b.url_id = bm_urls.url_id 
    and      b.bookmark_id <> :root_folder_id
    and     (    upper(local_title)      like :search_pattern
              or upper(url_title)        like :search_pattern
              or upper(complete_url)     like :search_pattern
              or upper(meta_keywords)    like :search_pattern
              or upper(meta_description) like :search_pattern)
    order by title

      </querytext>
</fullquery>

 
<fullquery name="bookmark_search_other">      
      <querytext>
      
    select   distinct complete_url,
             bookmark_id,
             nvl(local_title, url_title) as title, 
             meta_keywords, 
             meta_description, 
             folder_p,
             acs_permission.permission_p(bookmark_id, :browsing_user_id, 'admin') as admin_p
    from     (select bookmark_id, url_id, local_title, folder_p, owner_id 
              from bm_bookmarks start with bookmark_id in (select bookmark_id
                           from bm_bookmarks where parent_id = :package_id)
              connect by prior bookmark_id = parent_id) b, 
             bm_urls
    where    owner_id <> :browsing_user_id
    and      acs_permission.permission_p(bookmark_id, :browsing_user_id, 'read') = 't'
    and      folder_p  = 'f' 
    and      b.url_id = bm_urls.url_id 
    and     (   upper(local_title)      like :search_pattern
             or upper(url_title)        like :search_pattern
             or upper(complete_url)     like :search_pattern
             or upper(meta_keywords)    like :search_pattern
             or upper(meta_description) like :search_pattern)
    order by title

      </querytext>
</fullquery>

 
</queryset>
