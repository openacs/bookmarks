<?xml version="1.0"?>
<queryset>

<fullquery name="name_query">      
      <querytext>
      
select first_names||' '||last_name as name 
from   cc_users 
where  user_id = :user_id
      </querytext>
</fullquery>

 
</queryset>
