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
package com.service
{
	import mx.controls.Alert;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	[Bindable]
	public class BaseService{
		protected static function alert(event:ResultEvent):void{
			Alert.show(String(event.result),"Error");
		}
		
		protected static function saveSuccess(event:ResultEvent):void{
		}
		
		protected static function loadFault(event:FaultEvent):void{
			Alert.show("An Error Occured: " + event.toString());
		}
	}
}