<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>
<property name="viewed_user_id">@viewed_user_id;literal@</property>
<include src="bookmark-header">
<form method=post action=bookmark-permissions-2>
<input type="hidden" name="root_folder_id" value="@root_folder_id@">
<input type="hidden" name="viewed_user_id" value="@viewed_user_id@">
<table>

<tr>
  <th>Default (root) access permissions</th>
  <td><input type="checkbox" name="private_p" value="t" <if @old_private_p@ eq "t"> checked</if>> Private (no other registered users have read access to any of your bookmarks)</td>
</tr>

</table>

<center>
<input type="submit" value="Update Permissions">
</center>

</form>
