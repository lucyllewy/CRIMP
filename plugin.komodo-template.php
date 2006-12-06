<?php
/**
 *[[%(ask0:plugin name)]]: a plugin for CRIMP
 *(the Content Redirection Internet Management Program)
 *Copyright (C) 2005-2006 The CRIMP Team
 *Authors:          The CRIMP Team
 *Project Leads:    Martin "Deadpan110" Guppy <deadpan110@users.sourceforge.net>,
 *                  Daniel "Fremen" Llewellyn <diddledan@users.sourceforge.net>
 *                  HomePage:      http://crimp.sf.net/
 *
 *Revision info: $Id: plugin.komodo-template.php,v 2.4 2006-12-06 16:44:50 diddledan Exp $
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

class [[%(ask0:Plugin Name)]] implements iPlugin {
    public function execute() {
        $crimp = &$this->crimp;
        $dbg = &$crimp->debug;

        $pluginName = '[[%(ask0:Plugin Name)]]';

        /**
         *should this plugin defer itself?
         */
        $defer = [[%(ask:Should this plugin defer itself? (true or false):false)]];

        /**
         *check that we aren't locked
         */
        if ( $crimp->pluginLock($pluginName) ) {
            $dbg->addDebug('Exiting, as we are locked.');
            return;
        }

        /**
         *the value referenced by default configuration key, that you entered
         *in the komodo dialog, is stored in the variable $config
         */
        if ( !($config = $crimp->Config('[[%(ask1:Default Configuration Key)]]', $this->scope, $pluginName)) ) {
            $dbg->addDebug('Please define a <position /> tag in the config.xml file', WARN);
            return;
        }

        /**
         *the actual deferral check
         */
        if ( $defer && !$this->deferred ) {
            $dbg->addDebug('Deferring execution till later', PASS);
            $crimp->setDeferral($pluginName, $this->scope);
            return;
        }

        /**
         *BEGIN CUSTOM PLUGIN CODE HERE
         */
    }
}

?>
