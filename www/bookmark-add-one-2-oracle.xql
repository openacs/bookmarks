<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="url_add">      
      <querytext>
      
	begin
	   :1 := url.new (
           url_id => :url_id,
           url_title => :url_title,
	   host_url => :host_url,
	   complete_url => :complete_url,
           meta_keywords => :meta_keywords,
           meta_description => :meta_description,
           creation_user => :viewed_user_id,
           creation_ip => :creation_ip
	);
	end;
      </querytext>
</fullquery>

 
<fullquery name="bookmark_add">      
      <querytext>
      
    declare
      dummy_var integer;
    begin
      dummy_var := bookmark.new (
       bookmark_id => :bookmark_id,
       owner_id    => :viewed_user_id,
       url_id      => :url_id,
       local_title => :local_title,
       parent_id   => :parent_id,
       creation_user => :user_id,
       creation_ip => :creation_ip
	);       
    end;
      </querytext>
</fullquery>

 
</queryset>


