<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="toggle_open_close">      
      <querytext>
      
    begin
   bookmark.toggle_open_close(
   bookmark_id => :bookmark_id,
   browsing_user_id => :in_closed_p_id
    );
    end;
      </querytext>
</fullquery>

 
<fullquery name="toggle_open_close_all">      
      <querytext>
      
    begin
   bookmark.toggle_open_close_all(
   browsing_user_id => :in_closed_p_id,
   closed_p => :closed_p,
   root_id => bookmark.get_root_folder(
                package_id => :package_id,
                user_id    => :viewed_user_id
              )
    );
    end;
      </querytext>
</fullquery>

 
</queryset>
