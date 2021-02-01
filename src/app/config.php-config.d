	$snippets = glob("/opt/tt-rss/config.d/*.php");

	foreach ($snippets as $snippet) {
		require_once $snippet;
	}


