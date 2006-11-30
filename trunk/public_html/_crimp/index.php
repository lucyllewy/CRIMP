<?php
/**
 *CRIMP - Content Redirection Internet Management Program
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: index.php,v 1.2 2006-11-30 19:41:13 diddledan Exp $
 *
 *This library is free software; you can redistribute it and/or
 *modify it under the terms of the GNU Lesser General Public
 *License as published by the Free Software Foundation; either
 *version 2.1 of the License, or (at your option) any later version.
 *
 *This library is distributed in the hope that it will be useful,
 *but WITHOUT ANY WARRANTY; without even the implied warranty of
 *MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *Lesser General Public License for more details.
 *
 *You should have received a copy of the GNU Lesser General Public
 *License along with this library; if not, write to the Free Software
 *Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA
 */

define('CRIMP_HOME', dirname(__FILE__));

ini_set('include_path', './classes:'.ini_get('include_path'));

## debug routines
require_once('Debug.php');
$dbg = new Debug;

## our own config interface to the pear module
require_once('config.php');
$config = new crimpConf;
$conf = $config->get();

## HTML manipulation library
require_once('html.php');
## http2 class which extends the HTTP pear module (requires PEAR module "HTTP")
require_once('http2.php');
$http = new HTTP2;
## plugin architecture
require_once('plugin.php');
## Main class
require_once('crimp.php');
$crimp = new Crimp;

## do the plugin thing
$crimp->executePlugins();

## send the completed page
$crimp->sendDocument();

?>