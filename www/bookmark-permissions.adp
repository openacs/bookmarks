<master src="bm-master">
<property name="page_title">@page_title@</property>
<property name="context_bar_args">@context_bar_args@</property>
<property name="viewed_user_id">@viewed_user_id@</property>

<form method=post action=bookmark-permissions-2>
<input type=hidden name=root_folder_id value="@root_folder_id@">
<input type=hidden name=viewed_user_id value="@viewed_user_id@">
<table>

<tr>
  <th>Default (root) access permissions</th>
  <td><input type=checkbox name=private_p value="t" <if @old_private_p@ eq "t"> checked</if>> Private (no other registered users have read access to any of your bookmarks)</td>
</tr>

</table>

<center>
<input type=submit value="Update Permissions">
</center>

</form>
