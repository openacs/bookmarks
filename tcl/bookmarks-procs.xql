<?xml version="1.0"?>
<queryset>

<fullquery name="bm_handle_bookmark_double_click.dbclick">      
      <querytext>
      select count(*) 
                                          from   bm_bookmarks 
	                                  where  bookmark_id = :bookmark_id
      </querytext>
</fullquery>

 
<fullquery name="bm_context_bar_args.user_name">      
      <querytext>
      select first_names || ' ' || last_name from cc_users where object_id = :viewed_user_id
      </querytext>
</fullquery>

 
</queryset>
