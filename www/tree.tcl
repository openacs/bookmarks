ad_page_contract {

} {
   viewed_user_id:integer
   user_name
   write_p
}


doc_return 200 text/html "<html>

<head>
<title> Bookmarks for $user_name</title>
</head>

    <frameset rows=\"58,*\" frameborder=yes border=1 framespacing=1>
      <frame src=\"[export_vars -base top-frame { viewed_user_id write_p }]\" name=top marginwidth=0 marginheight=0 scrollbars=no>
      <frame src=\"[export_vars -base tree-frame { viewed_user_id }]\" name=main marginwidth=4 marginheight=0>
    </frameset>

<body bgcolor=white>

</html>"

