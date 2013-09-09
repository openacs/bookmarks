#Lists the most popular hosts and the most popular
#complete urls. To be included in other adp pages.
#
# by pmarklun@arsdigita.com


set maxrows [parameter::get -parameter MostPopularHostsAndURLsMaxN]

multirow create popular_hosts n_bookmarks host_url host_name
multirow create popular_urls n_bookmarks complete_url local_title

set browsing_user_id [ad_conn user_id]

set root_folder_id [ad_conn package_id]

set count_select_query "(select count(*) from (select bookmark_id, url_id from bm_bookmarks
                                  start with parent_id = :root_folder_id
                                  connect by prior bookmark_id = parent_id)
            where url_id = bm_urls.url_id
            and acs_permission.permission_p(bookmark_id, :browsing_user_id, 'read') = 't')"

# Get the most popular hosts
db_foreach popular_hosts "
    select unique host_url,
           $count_select_query as n_bookmarks
    from  bm_urls
    order by n_bookmarks desc
" {
    regsub {^http://([^/]*)/?} $host_url {\1} host_name
    multirow append popular_hosts $n_bookmarks $host_url $host_name

    if { [multirow size popular_hosts] >= $maxrows } {
	break
    }
}

# get the most popular urls
db_foreach popular_urls "
    select nvl(url_title, complete_url) as local_title, 
           complete_url, 
           $count_select_query as n_bookmarks
    from   bm_urls
    order by n_bookmarks desc
" {
    multirow append popular_urls $n_bookmarks $complete_url $local_title

    if { [multirow size popular_urls] >= $maxrows } {
	break
    }
}








