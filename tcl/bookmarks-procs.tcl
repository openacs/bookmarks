ad_library {
    TCL library for the bookmarks module.

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


ad_proc bm_folder_selection { user_id bookmark_id folder_p } {
    This procedure is used to present a list of available folders to 
    put bookmark or folder in.
} {
    # We cannot move folders to be their own children
    if { $folder_p == "t" } {
	set exclude_folders [db_map exclude_folders]
    } else {
	set exclude_folders ""
    }

    set package_id [ad_conn package_id]

    db_multirow folders folder_select "
    select /*+INDEX(bm_bookmarks bm_bookmarks_local_title_idx)*/ bookmark_id, 
    local_title,
    level as indentation
    from   bm_bookmarks
    where folder_p = 't'
    and owner_id = :user_id
    and bookmark_id <> :bookmark_id
    and parent_id <> :package_id
    and acs_permission.permission_p(bookmark_id, :user_id, 'write') = 't'
    $exclude_folders
    start with parent_id = :package_id
    connect by prior bookmark_id = parent_id
    " 
}


ad_proc bm_host_url {complete_url} {

    Takes a URL and returns the host portion of it (i.e.,
    http://hostname.com/), which always contains a trailing
    slash. Returns empty string if complete_url wasn't parseable.

} {
    if { [regexp {([^:\"]+://[^/]+)} $complete_url host_url] } {
	return "$host_url/"
    } else {
	return ""
    }
}


ad_proc bm_handle_bookmark_double_click { bookmark_id errmsg return_url } {
} {
	# check and see if this was a double click
	set dbclick_p [db_string dbclick "select count(*) 
                                          from   bm_bookmarks 
	                                  where  bookmark_id = :bookmark_id"]
	
	if {$dbclick_p == "1"} {   
	    ad_returnredirect $return_url
            ad_script_abort
	} else {

	    upvar \#[template::adp_level] n_errors n_errors
	    upvar \#[template::adp_level] error_list error_list

		set n_errors 1
		set error_list [list "There was an error making this insert into the database. $errmsg"]

	      uplevel \#[template::adp_level] {
  		ad_return_template "complaint"
  	    }
            ad_script_abort
	}
}


ad_proc bm_repeat_string { string iteration_number } {
} {
    if { $iteration_number <= 0} {
	return ""
    } 

    set return_string ""
    for { set i 0 } { $i < $iteration_number } { incr i } {
	append return_string $string
    }

    return $return_string
}


ad_proc bm_get_root_folder_id { package_id user_id } {
      Returns the id of the bookmark root folder of a user in a package
      instance. This root folder is used for default access permissioning 
      of a users bookmarks (bookmarks will inherit permissions).
} {
      set root_folder_id [db_exec_plsql fs_root_folder "
      begin
          :1 := bookmark.get_root_folder(
                package_id => :package_id,
                user_id    => :user_id);
      end;"]

      return $root_folder_id
}


ad_proc bm_user_can_write_in_some_folder_p { viewed_user_id } {
    Returns "t" if there is a folder that the browsing user can write
    in, and "f' otherwise.
} {
    set browsing_user_id [ad_conn user_id]

    set n_of_write_folders [db_string write_in_folders "select count(*) from bm_bookmarks
                     where owner_id = :viewed_user_id
                     and folder_p = 't'
                     and acs_permission.permission_p(bookmark_id, :browsing_user_id, 'write') = 't'"]

    return [ad_decode $n_of_write_folders "0" "f" "t"]
}


ad_proc bm_delete_permission_p { bookmark_id } {
    Returns boolean value indicating if the browsing user may delete
    the bookmark.
} {
    set browsing_user_id [ad_conn user_id]

    return [ad_decode [db_string delete_permission_p "select count(*) from bm_bookmarks 
	where acs_permission.permission_p(bookmark_id, :browsing_user_id, 'delete') = 'f'
	start with bookmark_id = :bookmark_id
	connect by prior bookmark_id = parent_id"] "0" "t" "f"]


}


ad_proc bm_require_delete_permission { bookmark_id } {
    This proc verifyes that the user may delete the bookmark/folder and all its
    contained bookmarks/folders.

} {
    if { [string equal [bm_delete_permission_p $bookmark_id] "f"] } {
	set n_errors 1
	set error_list [list "You either do not have delete permissions on this bookmark/folder, or you are trying to delete a folder that contains at least one bookmarks or folder that you may not delete"]
	ad_return_template "complaint"
	return -code return
    }
}


ad_proc bm_context_bar_args { arg_string viewed_user_id } {
    If viewed_user_id <> browsing_user_id we need to prefix the 
    context bar args with an entry for bookmarks of the viewed user. If the
    arg_string is empty it is assumed that we are on the index page and that otherwise
    the page has been linked from the index page.
} {
    set browsing_user_id [ad_conn user_id]
    
    if { ![string equal $browsing_user_id $viewed_user_id] && ![empty_string_p $viewed_user_id]} {
	# The user is viewing someone elses bookmarks
	# and we need the set the context bar so that 
	# he can go back to viewing his own bookmarks
	set user_name [db_string user_name "select first_names || ' ' || last_name from cc_users where object_id = :viewed_user_id" -default ""]

	if { [empty_string_p $arg_string] } {
	    # We are on the index page
	    return "\"Bookmarks of $user_name\""
	} else {
	    # We were linked from the index page
	    return "\[list \"index?viewed_user_id=$viewed_user_id\" \"Bookmarks of $user_name\"\] $arg_string"
	}
    } else {
	return $arg_string
    }
}


ad_proc bm_get_html_title { html_code } {

} {
    set title ""
    regexp -nocase {<title>([^<]*)</title>} $html_code match title

    if {[string length $title]> [ad_parameter URLTitleMaxLength] || [string length $title] > 499 } {
	set title "[string range $title 0 496]..."
    }

    return [string trim $title]
}


ad_proc bm_get_html_description { html_code } {

} {
    set description ""
    regexp -nocase {<meta name="description" content="([^"]*)"} $html_code match description

    if {[string length $description]> [ad_parameter URLDescriptionMaxLength] || [string length $description] > 3999 } {
	set description "[string range $description 0 3996]..."
    }

    return [string trim $description]
}

ad_proc bm_get_html_keywords { html_code } {

} {
    set keywords ""
    regexp -nocase {<meta name="keywords" content="([^"]*)">} $html_code match keywords

    if {[string length $keywords]> [ad_parameter URLKeywordsMaxLength] || [string length $keywords] > 3999 } {
	set keywords "[string range $keywords 0 3996]..."
    }

    return [string trim $keywords]
}


ad_proc bm_bookmark_private_p { bookmark_id } {

} {
    return [db_string bookmark_private_p "select bookmark.private_p(:bookmark_id) from dual"] 
}


ad_proc bm_update_bookmark_private_p { bookmark_id private_p} {

} {
	db_exec_plsql update_private_p {
	    begin
	       bookmark.update_private_p(:bookmark_id, :private_p);
	    end;
	}
}


ad_proc bm_initialize_in_closed_p { viewed_user_id in_closed_p_id package_id} {

} {
	db_exec_plsql initialize_in_closed_p {
	    begin
	       bookmark.initialize_in_closed_p(:viewed_user_id, :in_closed_p_id, :package_id);
	    end;
	}    
}

ad_proc -private bm_close_js_brackets {prev_folder_p prev_lev lev} {
	This helper function is used by the tree-dynamic.tcl page in
	constructing the bookmark tree for the javascript page.
} {
	set result ""
	if {$prev_folder_p && ($prev_lev >= $lev)} {
		# Empty folder. We need to add a fake bookmark to the folder or else
		# it will not have a folder icon attached to it.
		set i_str [string repeat "\t" $prev_lev]
		append result "$i_str\t\['Empty folder']\n"
		append result "$i_str],\n"
	}
	while {$prev_lev > $lev} {
		set i_str [string repeat "\t" [expr $prev_lev - 1]]
		append result "$i_str],\n"
		incr prev_lev -1
	}

	return $result
}
