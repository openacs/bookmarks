ad_library {
    Startup script for the bookmarks module.

    Credit for the ACS 3 version of this module goes to:
    @author David Hill (dh@arsdigita.com)
    @author Aurelius Prochazka (aure@arsdigita.com)
  
    The upgrade of this module to ACS 4 was done by
    @author Peter Marklund (pmarklun@arsdigita.com)
    @author Ken Kennedy (kenzoid@io.com)
    in December 2000.

    @creation-date December 2000
    @cvs-id $Id$
}


db_foreach bm_packages {
    select site_node.url(node_id) as path
    from   site_nodes
    where  object_id in (select package_id
                         from   apm_packages where package_key = 'bookmarks')
} {
    ad_register_proc GET ${path}bookmark.htm bm_export_to_netscape
}



ad_proc bm_export_to_netscape {} {

    Outputs a set of bookmarks in the standard Netscape bookmark.htm
    format.

} {

    set user_id [ad_maybe_redirect_for_registration]

    set package_id [ad_conn package_id]

    set root_folder_id [bm_get_root_folder_id $package_id $user_id]

    set name [db_string name "
    select first_names||' '||last_name as name 
    from   cc_users 
    where  user_id = :user_id"]

    set folder_list 0

    db_foreach bm_info {
        select   b.bookmark_id, 
	         b.url_id, 
                 b.local_title, 
	         acs_objects.creation_date, 
	         b.parent_id,
                 bm_urls.complete_url, 
	         b.folder_p
        from     (select /*+INDEX(bm_bookmarks bm_bookmarks_local_title_idx)*/ bookmark_id, url_id, local_title, folder_p, level lev, 
	          parent_id, owner_id, rownum ord_num from bm_bookmarks 
	          start with parent_id = :root_folder_id connect by prior bookmark_id = parent_id) b, 
	         bm_urls,
	         acs_objects
        where    owner_id       = :user_id
	and      acs_objects.object_id = b.bookmark_id
        and      b.url_id = bm_urls.url_id(+)
	order by ord_num
    } {

	if { [string equal $folder_list 0] } {
	    lappend folder_list $parent_id
	} else {
	    set previous_parent_id [lindex $folder_list [expr [llength $folder_list]-1]]	
	    if {$parent_id != $previous_parent_id} {

		set parent_location [lsearch -exact $folder_list $parent_id]
		
		

		if {$parent_location==-1} {
		    lappend folder_list $parent_id
		    append bookmark_html "<DL><p>\n\n"
		} else { 	    
		    set drop [expr [llength $folder_list]-$parent_location]
		    set folder_list [lrange $folder_list 0 $parent_location]
		    for {set i 1} {$i<$drop} {incr i} {
			append bookmark_html "</DL><p>\n\n"
		    }
		}
	    } elseif { [string equal $folder_p "t"] && [string equal $previous_folder_p "t"] } {
		# The previous folder was empty
		append bookmark_html "<DL><p>\n</DL><p>\n\n"
	    }
	}

	if {$folder_p=="t"} {
	    append bookmark_html "<DT><H3 ADD_DATE=\"[ns_time]\">$local_title</H3>\n\n"
	} else {
	    append bookmark_html "<DT><A HREF=\"$complete_url\" ADD_DATE=\"[ns_time]\" LAST_VISIT=\"0\" LAST_MODIFIED=\"0\">$local_title</A>\n\n"
	}

	set previous_folder_p $folder_p
    }

    set html "<!DOCTYPE NETSCAPE-Bookmark-file-1>

    <!-- This is an automatically generated file.

    It will be read and overwritten.

    Do Not Edit! -->

    <TITLE>Bookmarks for $name</TITLE>

    <H1>Bookmarks for $name</H1>

    <DL><p>

    $bookmark_html

    </DL><p>
    "

    
    doc_return  200 text/html $html
}


# The table bm_in_closed_p holds session data that needs to be removed
# to avoid the table growing to large (maximum size of the table would be
# number_of_bookmarks times number_of_users)
ad_schedule_proc 86400 bm_clean_up_session_data


ad_proc bm_clean_up_session_data {} {
The table bm_in_closed_p holds session data that needs to be removed
 to avoid the table growing to large (maximum size of the table would be
 number_of_bookmarks times number_of_users)
} {
    db_dml delete_old_in_closed_p "delete from bm_in_closed_p where creation_date < (sysdate - 1)"
}


