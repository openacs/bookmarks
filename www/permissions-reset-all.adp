<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>

Are you sure that you want to delete the individual access permissions
on the following bookmarks to make your default (root) permissions apply?

<ul>
<multiple name="direct_permissions">
<li>@direct_permissions.local_title@ <if @public_p;literal@ true>private</if><else>public</else></li>
</multiple>
</ul>

<form method=post action=permissions-reset-all-2.tcl>
<input type="hidden" name="root_folder_id" value="@root_folder_id@">
<input type="hidden" name="viewed_user_id" value="@viewed_user_id@">
<center>
<input type="submit" value="Yes, Proceed">
</center>
</form>
