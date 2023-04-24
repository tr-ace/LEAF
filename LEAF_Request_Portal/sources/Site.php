<?php
/*
 * As a work of the United States government, this project is in the public domain within the United States.
 */

namespace Portal;

class Site
{
	public $siteRoot = '';

	private $db;

	private $login;

	public function __construct($db, $login)
	{
		$this->db = $db;
		$this->login = $login;

        // For Jira Ticket:LEAF-2471/remove-all-http-redirects-from-code
//		$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] == 'on' ? 'https' : 'http';
        $protocol = 'https';
		$this->siteRoot = "{$protocol}://" . HTTP_HOST . dirname($_SERVER['REQUEST_URI']) . '/';
	}

	public function getAllSitePaths()
	{
		$res = $this->db->prepared_query("SELECT site_type, site_path FROM sites ORDER BY site_path ASC", null);
		return $res;
	}

	public function setSitemapJSON()
    {
        if (!$this->login->checkGroup(1))
        {
            return 'Admin access required';
        }

        $vars = array(':input' => $_POST['sitemap_json']);
        $this->db->prepared_query('UPDATE settings SET data=:input WHERE setting="sitemap_json"', $vars);

        return 1;
    }

	public function setHomeMenuJSON(array $arrayIn = []): string|int {
        if (!$this->login->checkGroup(1)) {
            return 'Admin access required';
        }
        foreach ($arrayIn as $i => $item) {
            $arrayIn[$i]['title'] = \Leaf\XSSHelpers::sanitizeHTMLRich($item['title']);
            $arrayIn[$i]['subtitle'] = \Leaf\XSSHelpers::sanitizeHTMLRich($item['subtitle']);
            $arrayIn[$i]['link'] = \Leaf\XSSHelpers::xscrub($item['link']);
            $arrayIn[$i]['icon'] = \Leaf\XSSHelpers::xscrub($item['icon']);
        }
        $home_menu_json = json_encode($arrayIn);

		$strSQL = 'INSERT INTO settings (setting, `data`)
			VALUES ("home_menu_json", :home_menu_json)
			ON DUPLICATE KEY UPDATE `data`=:home_menu_json';
        $vars = array(':home_menu_json' => $home_menu_json);

        $this->db->prepared_query($strSQL, $vars);

        return 1;
    }
}
