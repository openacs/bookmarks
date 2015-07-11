<master>
<property name="doc(title)">@page_title;literal@</property>
<property name="context">@context;literal@</property>
<include src="bookmark-header">
<% set hidden_form_vars "<input type="hidden" name="return_url" value="@return_url@">
<input type="hidden" name="viewed_user_id" value="@viewed_user_id@">
<input type="hidden" name="bookmark_id" value="@bookmark_id@">" %>

<h3>Add one Bookmark</h3>
Insert the URL below.  If you leave the title blank, we will 
attempt to get the title from the web site.  

<form action=bookmark-add-one method=post name=topform>
@hidden_form_vars;noquote@

<table>
<tr>
   <td valign="top" align="right">URL:</td>
   <td align="left"><input name="complete_url" size="70" maxlength="500" value="@complete_url@"></td>
</tr>
<tr>
   <td valign="top" align="right">Title (Optional):</td>
   <td align="left"><input name="local_title" size="70" maxlength="500" value="@local_title@"></td>
</tr>

<tr>
    <td>Folder</td>
    <td><include src=folder-selection bookmark_id="@bookmark_id;literal@" folder_p="f" default_id="" viewed_user_id="@viewed_user_id;literal@"><br>
    <a href="folder-add?return_url=@this_url_urlenc;noquote@">create a new folder</a></td>
</tr>

<tr>
   <td>
   </td>
   <td align="left">
   <input type="submit" value="Add">
   </td>
</tr>
</table>
</form>

<h3>How to add a Bookmark when you are browsing</h3>
To be able to add to your bookmarks in this system when you are
browsing you may use a so called Bookmarklet (which is a Bookmark in
your browser containing a line of JavaScript instead of a url). Such a 
Bookmarklet enables you to bookmark pages of interest
without interrupting your browsing so that adding Bookmarks to this
system becomes just as easy as adding bookmarks in your browser. To
enable this feature you may do the following. Right click on <a
href="@bookmarklet@">this link</a> and choose to add it as a Bookmark
(in Internet Explorer it is called Favorite). In Netscape you may then
preferably rename this Bookmark (for example to "Add Bookmark") and
move it to your toolbar so that you have an
easily accessible button to press every time you want to bookmark a page. 


<h3>Import multiple bookmarks from Netscape or Microsoft Internet Explorer bookmark.htm file</h3>

<form enctype=multipart/form-data method=POST action=bookmarks-import>
@hidden_form_vars;noquote@

Netscape users: Just specify your bookmark file<br>
Users of new versions of IE: Export your shortcuts to Netscape format, then
                             specify the file<br>

<p>
<table>
<tr>
<td>Bookmarks File: <input type="file" name="upload_file" size="10"></td>
<td><input type="submit" value="Import file"></td>
</tr>
</table>
<p> 











