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
 * Guo Lei <guolei@eleutian.com>
 * Seven Du <seven@eleutian.com>
 */
package realtime.services
{
	import com.service.RealtimeService;
	import flash.external.ExternalInterface;
	import mx.controls.Alert;
	public class SocketService extends RealtimeService
	{
		
	
		override protected function onDataLoad(data:String):void
		{
 			ExternalInterface.call("realtime.receiveData", data);
		}
		
		override protected function logger(msg:String):void
		{
			ExternalInterface.call("realtime.logger", msg);
		}
		
		override protected function addSubscriber(subscriber:String):void
		{
			ExternalInterface.call("realtime.addSubscriber", subscriber);
			
		}
		override protected function removeSubscriber(subscriber:String):void
		{
			ExternalInterface.call("realtime.removeSubscriber", subscriber)
		}
		override protected function updateSubscribers(subscribers:String):void
		{
			ExternalInterface.call("realtime.updateSubscriber", subscribers)
		}
		override protected function setConnectionMethod(meth:String):void
		{
				ExternalInterface.call("realtime.set_connection_method", meth);
		}
		
		private static var instance:SocketService;

		public function SocketService()
		{
			if (instance != null)
			{
				throw new Error("Singleton Error at Service !");
			}
			instance=this;
		}

		public static function getInstance():SocketService
		{
			if (instance == null)
			{
				instance=new SocketService();
			}
			return instance;
		}
	}

}