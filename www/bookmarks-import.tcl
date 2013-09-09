ad_page_contract {

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
    upload_file
    upload_file.tmpfile:tmpfile

    bookmark_id:integer
    return_url
    viewed_user_id:integer
} -validate {

    non_empty_file {

        if { [file size ${upload_file.tmpfile}] == 0 } {
	    ad_complain "The bookmark file you specified is either empty or invalid."
	} 
    }

} -properties {

    page_title:onevalue
    context:onevalue    
    import_list:onevalue
    return_url:onevalue

} -return_errors error_list

# Read the file and check its size
if [catch { set contents [read [open ${upload_file.tmpfile} r] [parameter::get -parameter MaxNumberOfBytes -default 1000000]] } errmsg] {
    lappend error_list "We had a problem processing your request:
	    <p>$errmsg"
}

# Check that the file is of right format
if {![regexp {<DL>(.*)</DL>} $contents match format_p]} {
    lappend error_list "You file does not appear to be a valid bookmark file"
}

if { [info exists error_list] } {
    set n_errors [llength $error_list]
    ad_return_template "complaint"
    return
}



# Let's check for a doubleclick first
if { [db_string dbclick_check "
 select count(bookmark_id) as n_existing
 from   bm_bookmarks 
 where  bookmark_id = :bookmark_id"] != 0 } {
    # must have doubleclicked
    ad_returnredirect $return_url
    ad_script_abort
}

set page_title "Import Statistics"

set context [bm_context_bar_args [list [list "bookmark-add-import?[export_vars -url {viewed_user_id return_url}]" "Add/Import Bookmarks"] $page_title] $viewed_user_id]


# set flags to be used parsing the input file.
set package_id [ad_conn package_id]
set user_id [ad_conn user_id]
set creation_ip [ad_conn peeraddr]

set parent_id [bm_get_root_folder_id $package_id $viewed_user_id]
lappend folder_list $parent_id

# split the input file 'contents' on returns and rename it 'lines'
set lines [split $contents "\n"]

# connect to the default pool and start a transaction.
foreach line $lines {
    
    set depth [expr [llength $folder_list]-1]

    # checks if the line represents a folder
    if {[regexp {<H3[^>]*>([^<]*)</H3>} $line match local_title]} {

	if {[string length $local_title] > 499} {
	    set local_title "[string range $local_title 0 496]..."
	}

	# test for duplicates	
	if { [db_string n_dp_folder "
	    select count(*) from bm_bookmarks
	    where  owner_id = :viewed_user_id
	    and    parent_id = :parent_id
	    and    folder_p = 't'
	    and    local_title = :local_title"] != 0 } {	

	    lappend import_list "Duplicate folder \"$local_title\""
	    set parent_id [db_string bm_parent "
	    select bookmark_id
	    from   bm_bookmarks
	    where  folder_p = 't'
	    and    owner_id = :user_id
	    and    local_title = :local_title"]

	    } else {
		# insert folder into bm_bookmarks
		if [catch {db_exec_plsql folder_insert "
		declare
		dummy_var integer;
		begin
		   dummy_var := bookmark.new (
		   bookmark_id => :bookmark_id,
		   owner_id    => :viewed_user_id,
		   local_title => :local_title,
		   parent_id   => :parent_id,
		   folder_p    => 't',
		   creation_user => :user_id,
		   creation_ip => :creation_ip
		);       
		end;"} errmsg] {
		    set n_errors 1
		    set error_list [list "We were unable to create your user record in the database.  Here's what the error looked like:
		    <blockquote>
		    <pre>
		    $errmsg
		    </pre>
		    </blockquote>"]
		    ad_return_template "error"
                    return
		} else {
		    # success in inserting folder into bm_bookmarks
		    lappend import_list "Inserting folder \"$local_title\""

		    lappend folder_list $bookmark_id
		    set parent_id $bookmark_id

		    set bookmark_id [db_nextval acs_object_id_seq]
		}
	    }
	}
	
    # check if the line ends the current folder
    if {[regexp {</DL>} $line match]} {
	set folder_depth [expr [llength $folder_list]-2]
	if {$folder_depth<0} {
	    set folder_depth 0
	}
	set folder_list [lrange $folder_list 0 $folder_depth]
	set parent_id [lindex $folder_list $folder_depth]

    }

    # check if the line is a url
    if {[regexp {<DT><A HREF="([^"]*)"[^>]*>([^<]*)</A>} $line match complete_url local_title]} {

	set host_url [bm_host_url $complete_url]

	if { [empty_string_p $host_url] } {
	    continue
	}
	
	if { [string length $complete_url] > 499 } {
	    lappend import_list "URL is too long for our database, skipping: \"$complete_url\""
	 
	} else {	 
	    # check to see if we already have the url in our database
	    set url_id [db_string bm_dp_url "
		    select url_id
		    from   bm_urls
		    where  complete_url = :complete_url" -default ""]

	    set url_p 1 

	    # if we don't have the url, then insert the url into the database
	    if [empty_string_p $url_id] {

		set url_id [db_nextval acs_object_id_seq]

		if [catch {db_exec_plsql new_url "		
		declare
		   dummy_var integer;
		begin
		dummy_var := url.new (
		   url_id => :url_id,
		   url_title => :local_title,
		   host_url => :host_url,
		   complete_url => :complete_url,
		   creation_user => :viewed_user_id,
		   creation_ip => :creation_ip
		);
		end;"} errmsg] {
		    lappend import_list "We were unable to insert the url $complete_url into the database due to the following
		    database error: <pre>$errmsg</pre>"
		    set url_p 0
		} 
	    }

	# now we have a url_id (either from query or insert), if it is not an exact duplicate 
	# of one the user already has (including folder location), lets put it in the users bookmark list.
	if {$url_p == 1} {
	    if { [db_string dp "
		select count(bookmark_id) 
		from   bm_bookmarks
		where  url_id = :url_id
		and    owner_id = :viewed_user_id
		and    parent_id = :parent_id"] != 0 } {

		lappend import_list "You already added: \"$local_title\""

	    } else {
	    
		# try to insert bookmark into user's list	
		if [catch {db_exec_plsql bookmark_insert  "
		
		declare
		   dummy_var integer;
		begin
		   dummy_var := bookmark.new (
		   bookmark_id => :bookmark_id,
		   owner_id    => :viewed_user_id,
		   url_id      => :url_id,
		   local_title => :local_title,
		   parent_id   => :parent_id,
		   creation_user => :user_id,
		   creation_ip => :creation_ip
		);       
		end;" } errmsg] {

		    # if it was not a double click, produce an error
		    if { [db_string dbclick  {
			select count(bookmark_id) 
			from   bm_bookmarks 
			where bookmark_id = :bookmark_id} ] == 0 } {
			    set n_errors 1
			    set error_list [list "We were unable to create your user record in the database.  Here's what the error looked like:
			    <blockquote>
			    <pre>
			    $errmsg
			    </pre>
			    </blockquote>"]
			    ad_return_template "error" 
                            return
			} else { 
			    # assume this was a double click
			    ad_returnredirect $return_url
                            ad_script_abort
			} 
		    } else {
			# insert into bm_bookmarks succeeded
			lappend import_list "Inserting url:\"$local_title\""
		    
			set bookmark_id [db_nextval acs_object_id_seq]
		    }
		}
	    }
	}
    }
}    

# Test for empty import_list before returning
if { [info exists import_list] } {
    # Do nothing..it's ok...
} else {
    # For some reason, nothing got inserted
    lappend import_list "Hmmm...the file seemed ok, but nothing was imported. Sorry!"
}

