<?xml version="1.0"?>
<queryset>

<fullquery name="user_urls">      
      <querytext>
      
    select u.first_names || ' ' || u.last_name as name, 
           bml.local_title,
           complete_url
    from   cc_users u, 
           bm_bookmarks bml, 
           bm_urls bmu
    where  u.user_id = bml.owner_id
    and    bml.url_id = bmu.url_id
    and    bmu.host_url = :host_url
    order by name

      </querytext>
</fullquery>

 
</queryset>
