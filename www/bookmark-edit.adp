<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>


<form method=post action=bookmark-edit-2>
@export_form_vars;noquote@
<input type="hidden" name=bookmark_id value="@bookmark.bookmark_id@">
<table>
 
<if @bookmark.folder_p@ eq "f">
<tr> 
<td align=right valign=top>URL:</td> 
<td align=left><input type=text size=40 maxlength=500 name=complete_url value="@bookmark.complete_url@"></td>
</if>

<tr>
<td align=right valign=top>Title:</td>
<td align=left><input type=text maxlength=500 size=40 name=local_title value="@bookmark.local_title@"></td>
</tr>

<tr>
  <td align=right valign=top>Parent Folder:</td>
  <td><include src=folder-selection bookmark_id=@bookmark.bookmark_id;noquote@ folder_p="@bookmark.folder_p;noquote@" default_id="@bookmark.parent_id;noquote@" viewed_user_id="@bookmark.owner_id;noquote@"></td>
</tr>

<tr>
  <td align=right valign=top>Access Permissions</td>
<if @public_possible_p@ eq "t">
<td><input type=checkbox name=private_p value="t" <if @old_private_p@ eq "t"> checked</if>> Private (no other registered users have read access <if @folder_bookmark@ eq "folder">to this folder or any of its contained bookmarks and folders</if>)</td>
</if>
<else>
<td>This bookmark is private since it is contained in a private folder. To make this bookmark public you need to make the topmost private folder containing this bookmark public.</td>
</else>
</tr>

<td></td>
<td><input type=submit value="Submit these updates"></td>

</table>
</form>


<ul>

<if @delete_p@ eq "t">
<p>  
<li><a href="bookmark-delete?bookmark_id=@bookmark.bookmark_id@&viewed_user_id=@viewed_user_id@&return_url=@return_url_urlenc@">Delete this <%= [ad_decode @bookmark.folder_p@ "t" "folder" "bookmark"] %></a>
</li>
</if>

</ul>
