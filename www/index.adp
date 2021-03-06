<master>
  <property name="doc(title)">@page_title;literal@</property>
  <property name="context">@context;literal@</property>
  <property name="header_stuff">
    <script runat="client">
      function launch_window(file) {
          window.open(file,'bookmarks','toolbar=no,location=no,directories=no,status=no,scrollbars=auto,resizable=yes,copyhistory=no,width=350,height=480')}
    </script>
  </property>

<%
set folder_bgcolor [parameter::get -parameter FolderBGColor -default "#f3f3f3"]
set bookmark_bgcolor  [parameter::get -parameter BookmarkBGColor -default "#ffffff"]
set edit_anchor "<font size=-1>Edit</font>"
set delete_anchor "<font size=-1>Delete</font>"
%>

<include src=bookmark-header>
<if @viewed_user_id@ ne "0">
<p>
Sort by: [ <if @sort_by@ eq "access_date"><a href="index?viewed_user_id=@viewed_user_id@&amp;sort_by=name">name</a></if><else><b>name</b></else> | 
<if @sort_by@ eq "name"><a href="index?viewed_user_id=@viewed_user_id@&amp;sort_by=access_date">access date</a></if><else><b>access date</b></else> 
<!-- | <a href="index?viewed_user_id=@viewed_user_id@&amp;sort_by=creation_date">creation date</a> --> ]

</p>

<form action="search" method=post>
<input type="hidden" name="return_url" value="index">
<input type="hidden" name="viewed_user_id" value="@viewed_user_id@">

Search bookmarks for: <input name="search_text" type="text" size="20"><input type="submit" value="Search">
</form>

<p>

<table bgcolor=$folder_bgcolor cellpadding="0" cellspacing="0" border="0" width="100%">
<tr>
<td width="100%"><img border="0" src=pics/ftv2folderopen.gif
align=top><b> Bookmarks for @user_name;noquote@ </b> &nbsp; &nbsp;
<a href="toggle-open-close?action=close_all&amp;viewed_user_id=@viewed_user_id@&amp;sort_by=@sort_by@&amp;browsing_user_id=@browsing_user_id@">Close</a>/<a href="toggle-open-close?action=open_all&amp;viewed_user_id=@viewed_user_id@&amp;sort_by=@sort_by@&amp;browsing_user_id=@browsing_user_id@">Open</a> All Folders</td>
</tr>
</table>


<multiple name="bookmark">
    
    <% set decoration_open ""
       set decoration_close ""
    if {[string is false @bookmark.folder_p;literal@] && [string compare @bookmark.last_checked_date@ @bookmark.last_live_date@] } {
	append decoration_open "<i>"
	append decoration_close "</i>"
    }

    if {[string is true @bookmark.folder_p;literal@]} {
	append decoration_open "<b>"
	append decoration_close "</b>"
    }

    regsub -all {'|\"} @bookmark.bookmark_title;literal@ {} javascript_title

    set action_bar ""

    if { [string is true @bookmark.admin_p;literal@] } {
       lappend action_bar [subst {
	   <a href="bookmark-edit?viewed_user_id=@viewed_user_id;literal@&amp;bookmark_id=@bookmark.bookmark_id;literal@&amp;return_url=@return_url_urlenc;literal@">$edit_anchor</a>
       }]
    }
    if { [string is true @bookmark.delete_p;literal@] } {
	lappend action_bar [subst {
	    <a href="bookmark-delete?bookmark_id=@bookmark.bookmark_id;literal@&amp;return_url=@return_url_urlenc;literal@&amp;viewed_user_id=@viewed_user_id;literal@">$delete_anchor</a>
	}]
    } 

    if { [string is false @bookmark.folder_p;literal@]} {
	set url "bookmark-access?bookmark_id=@bookmark.bookmark_id;literal@&url=[ad_urlencode @bookmark.complete_url;literal@]"
	set bgcolor $bookmark_bgcolor
	set image_url "pics/ftv2doc.gif"
	lappend action_bar [subst {
	    <a href="bookmark-view?bookmark_id=@bookmark.bookmark_id;literal@"><font size=-1>Details</font></a>
	}]
    } else {
	set bgcolor $folder_bgcolor
	set url "toggle-open-close?bookmark_id=@bookmark.bookmark_id;literal@&viewed_user_id=@viewed_user_id;literal@&sort_by=@sort_by@&browsing_user_id=@browsing_user_id;literal@"

	# different image_urls for whether or not the folder is open
	if { [string is true @bookmark.closed_p;literal@]} {
	    set image_url "pics/ftv2folderclosed.gif"
	} elseif {[string is false @bookmark.closed_p;literal@]} {
	    set image_url "pics/ftv2folderopen.gif"
	}
    }

    set action_bar [ad_decode $action_bar "" "" "<img src=\"pics/spacer.gif\" alt='spacer' width='5' height='1'> \[[join $action_bar { | }]\]" ]
    set private_text [ad_decode @bookmark.private_p;literal@ "t" "<font size='-1' color='red'>private</font>" ""]

    %>

    <table bgcolor="@bgcolor@" cellpadding="0" cellspacing="0" border="0" width="100%">
    <tr>
    <td valign="top"><img src="pics/spacer.gif" alt="spacer"  width=<%=[expr {[expr {@bookmark.indentation@ - 1}] * 24}]%> height="1"></td>

    <td><a href="@url@"><img width="24" height="22" border="0" src="<%= $image_url %>" align="top"></a></td>
    <td width="100%"><a href="@url@">@decoration_open;literal@@bookmark.bookmark_title;literal@@decoration_close;literal@</a> @action_bar;noquote@ @private_text;literal@</td>
    </tr>
    </table>
	  
</multiple>


<if @bookmark:rowcount@ eq 0>
    <if @viewed_user_id@ eq @browsing_user_id@>
    You don't have any bookmarks stored in the database. <p>
    </if>
    <else>
    This user has no bookmarks that you have permission to see.
    </else>
</if>

<p>
Key to bookmark display:
<table>
<tr>
<td><ul><li> <i> Unreachable links appear like this. These links may not be completely dead, but they were unreachable by our server on last attempt.</i></ul> </td>
</tr>
</table>

</if> <else>
You need to <a href="/register/?return_url=@this_url_urlenc@">login
</a> 
to this system to be able to
manage your bookmarks. However, without  logging in you may <a href="bookmarks-user-list">view public bookmarks of registered users</a>
</else>
