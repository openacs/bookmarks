<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="insert_or_update_url">      
      <querytext>
      
    begin
    :1 := url.insert_or_update (
    url_title => :local_title,
    host_url => :host_url,
    complete_url => :complete_url,
    creation_user => :creation_user,
    creation_ip => :creation_ip
    );
    end;
      </querytext>
</fullquery>

 
<fullquery name="update_in_closed_p">      
      <querytext>
      
begin
bookmark.update_in_closed_p_all_users (
                bookmark_id => :bookmark_id,
                new_parent_id => :parent_id
);
end;
      </querytext>
</fullquery>

 
</queryset>
