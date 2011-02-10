/*
 * realtime-socket, a flash client connect to a comet socket.
 * Copyright (C) 2010-2011, Eleutian Technology, LLC <http://www.eleutian.com>
 *
 * Version: Apache License 2.0
 *
 * The content of this file is licensed under the Apache License, Version 2.0.  (the "License").
 * You may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.apache.org/licenses/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is realtime-socket.
 *
 * The Initial Developer of the Original Code is
 * Jonathan Pally <jonathan@eleutian.com>
 * Portions created by the Initial Developer are Copyright (C)
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Seven Du <seven@eleutian.com>
 */
package 
{

import flash.display.Sprite;
import flash.display.LoaderInfo;
import flash.text.TextField;
import realtime.services.SocketService

public class realtime extends Sprite
{

	public function realtime()
	{
		var display_txt:TextField = new TextField();
					display_txt.text = LoaderInfo(this.root.loaderInfo).parameters.realtime_channel;
					addChild(display_txt);
		SocketService.getInstance().initSocket(LoaderInfo(this.root.loaderInfo).parameters);
					
	}

}
}