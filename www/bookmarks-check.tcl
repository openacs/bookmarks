ad_page_contract {
    This page checks all urls belonging to the 
    user and lets him delete the ones that are dead.

    Since it is not easily possible to build a page
    incrementally (to flush) using the ArsDigita Templating
    System, I was forced to use the good old ns_write on this
    page.

    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id$
} {
    return_url
    {viewed_user_id:integer ""}
} 

set page_title "Checking Bookmarks"

set context [bm_context_bar_args "\"$page_title\"" $viewed_user_id]

set package_id [ad_conn package_id]

set browsing_user_id [ad_conn user_id]

if { [empty_string_p $viewed_user_id] } {
    # Only admins can call this page for all users
    ad_require_permission $package_id admin

    set root_folder_id $package_id
} else {
    # Only check urls belonging to the viewed user
    set root_folder_id [bm_get_root_folder_id [ad_conn package_id] $viewed_user_id]
}

set check_list [db_list_of_lists bookmark_list "
select url_id,
       complete_url,
       nvl(url_title, complete_url) as url_title
       from bm_urls
       where exists (select 1 from (select bookmark_id, url_id from bm_bookmarks
                                                     start with parent_id = :root_folder_id 
                                                     connect by prior bookmark_id = parent_id) bm
                                      where bm.url_id = bm_urls.url_id
                                      and acs_permission.permission_p(bm.bookmark_id, :browsing_user_id, 'delete')= 't' )"]


# We want to give the user something to look at before we start contacting
# the foreign hosts
ReturnHeaders
ns_write "[ad_header $page_title]

<h2>$page_title</h2>

[eval ad_context_bar [bm_context_bar_args "\"$page_title\"" $viewed_user_id]]
<hr>
"

if { ![empty_string_p $check_list] } {
    ns_write "URLs are being checked. This might take some time - so please have some patience...

Links that aren't reachable will appear with a checkbox in front of
them and the words <font color=red>NOT FOUND</font> after the link.
If you want to delete these links, simply click the checkbox and then
the \"Delete selected links\" button at the bottom of the page.
<p>"

} else {
    ns_write "There are no bookmarks to check
    [ad_footer]"
    return
}

set form_opened_p f
set dead_count 0

foreach check_set $check_list {

    set checked_url [ns_set create]

    set url_id       [lindex $check_set 0]
    set complete_url [lindex $check_set 1]
    set url_title  [lindex $check_set 2]

    # we only want to check http:

    if { [regexp -nocase "^mailto:" $complete_url] ||  [regexp -nocase "^file:" $complete_url] || (![regexp -nocase "^http:" $complete_url] && [regexp {^[^/]+:} $complete_url]) || [regexp "^\\#" $complete_url] } {
	# it was a mailto or an ftp:// or something (but not http://)
	# else that http_open won't like (or just plain #foobar)

	ns_write "<p> <table border=0 cellpadding=0 cellspacing=0>
	<tr>
	<td colspan=2>
	Skipping <a href=\"[ad_quotehtml $complete_url]\"> [ad_quotehtml $url_title] </a>....</td>
	</tr>
	</table>"

	continue
    } 
   
    # strip off any trailing #foo section directives to browsers
    regexp {^(.*/?[^/]+)\#[^/]+$} $complete_url dummy complete_url
    if [catch { set response [util_get_http_status $complete_url] } errmsg ] {
	# we got an error (probably a dead server)
	set response "probably the foreign server isn't responding at all"
    }
    if {$response == 404 || $response == 405 || $response == 500 } {
	# we should try again with a full GET 
	# because a lot of program-backed servers return 404 for HEAD
	# when a GET works fine
	if [catch { set response [util_get_http_status $complete_url 1] } errmsg] {
	    set response "probably the foreign server isn't responding"
	} 
    }

    ns_set put $checked_url url_id $url_id
    if { $response != 200 && $response != 302 } {
	ns_set put $checked_url last_live_date ""

	if { [string equal $form_opened_p "f"] } {
	    set form_opened_p "t"
	    ns_write "<form action=delete-dead-links method=post>
	    <input type=\"hidden\" name=\"return_url\" value=\"$return_url\">
	    <input type=\"hidden\" name=\"viewed_user_id\" value=\"$viewed_user_id\">"
	}

	set delete_html "<td>
	<input type=checkbox name=deleteable_link value=$url_id></td><td>"

	ns_write "<p> <table border=0 cellpadding=0 cellspacing=0>
	<tr>
	$delete_html
	<a href=\"[ad_quotehtml $complete_url]\">[ad_quotehtml $url_title]</a>.... <font color=red>NOT FOUND</font> [ad_quotehtml $response] </td></tr></table>"

	incr dead_count

	} else {
	    set set_last_live_date_to_now [db_map set_last_live_date_to_now]
	    ns_set put $checked_url last_live_date $set_last_live_date_to_now
	    # ns_set put $checked_url last_live_date "sysdate"
	    set url_content ""
	    if {![catch {ns_httpget $complete_url 3 1} url_content]} {

		set title [bm_get_html_title $url_content]
		set description [bm_get_html_description $url_content]
		set keywords [bm_get_html_keywords $url_content]
	    
		if { ![empty_string_p $keywords] || ![empty_string_p $description] } {
		    set keywords_or_description_p "t"
		} else {
		    set keywords_or_description_p "f"
		}

		ns_set put $checked_url title $title
		ns_set put $checked_url description $description
		ns_set put $checked_url keywords $keywords

		ns_write "<p> <table border=0 cellpadding=0 cellspacing=0>
	<tr>
	<td><a href=\"[ad_quotehtml $complete_url]\">[ad_quotehtml $url_title]</a>.... FOUND &nbsp; [ad_decode $title "" "" "title: $title"]</td>
	</tr>
	</table>"
	  }

      }
	  
      lappend checked_list $checked_url
}




foreach checked_url $checked_list {
    set url_id [ns_set get $checked_url url_id]
    set title [ns_set get $checked_url title]
    set description [ns_set get $checked_url description]
    set keywords [ns_set get $checked_url keywords]
    set last_live_date [ns_set get $checked_url last_live_date]

    if { ![empty_string_p $last_live_date] } {
	set last_live_clause ", last_live_date = $last_live_date"
    } else {
	set last_live_clause ""
    }

    db_dml bookmark_update_last_checked "
    update bm_urls 
    set    last_checked_date = sysdate,

    url_title= :title,
    meta_description= :description,
    meta_keywords= :keywords

    $last_live_clause

    where  url_id = :url_id"
}


if { $dead_count > 0 } {
    ns_write "<p>
    <input type=submit value=\"Delete selected links\">
    </form>
    [ad_footer]"
} else {
    ns_write "<p> [ad_footer]"
}
