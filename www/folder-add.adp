<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<include src="bookmark-header">


<form action=folder-add-2 method=post>
<input type="hidden" name=bookmark_id value="@bookmark_id@">
<input type="hidden" name=return_url value="@return_url@">
<input type="hidden" name=viewed_user_id value="@viewed_user_id@">

<table>
<tr>
  <td valign=top align=right>Input Folder Name:</td>
  <td><input name=local_title></td>
</tr>
<tr>
  <td valign=top align=right>Place in folder:  
  <img border=0 src=pics/ftv2folderopen align=top></td>
  <td><include src="folder-selection" bookmark_id="@bookmark_id;noquote@" folder_p="t" default_id="" viewed_user_id=@viewed_user_id;noquote@></td>
</tr>
<tr>
  <td></td>
  <td><input type=submit value=Submit></td>
</form>
</tr>
</table>

