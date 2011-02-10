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

/////////////////////////////////
// Realtime Base Class
//////////////////////////////

/* Usage:
1. Subclass This Class
2. Initialize by calling initSocket.  You must pass a parameters object that should contain:
     - realtime_host
     - realtime_port
     - realtime_last_time (optional)
	 - realtime_channel
	 - realtime_subscriber
	 NOTE: channel and subscriber can be passed in seperately as parameters to the initSocket function
	
3. Override appropriate functions:
	- OnDataLoad(data:String) to receive raw data or OnXMLLoad(data:XML) to receive XML data
	- logger(msg:String) to receive log messages.  By default log messages are trace(msg).
	- addSubscriber(subscriber:String) to know when a subscriber is added to the channel
	- removeSubscriber(subscriber:String) to know when a subscriber is removed from the channel
	- updateSubscribers(subscribers:String) called whenever the list of subscribers changes.
	- setConnectionMethod(meth:String) called when connection method to server is updated.
*/

package com.service
{

	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.XMLSocket;
	import flash.utils.Timer;
	import mx.utils.Base64Encoder;
	
	public class RealtimeService extends EventDispatcher
	{
		public var connectStatus:String;

		private var last_time:String;

		private var socket:XMLSocket;
		private var loader:URLLoader = new URLLoader();
		private var refresh_subscriber_interval:int;
		private var subscriber_id:String;
		private var subscribing:Boolean = false;
		private var subscriberList:Array = new Array();
		private var channel:String;
		private var timer:Timer;
		private var parameters:Object;
		private var timeoutTimer:Timer
		private var refreshTimer:Timer
		private var cancelSocket:Boolean;  //Used for the "fake" timeout

		public function initSocket(_parameters:Object, _channel:String = null, _subscriber:String = null):void
		{
			parameters = _parameters;

			if (parameters.realtime_last_time)
			{
				last_time = parameters.realtime_last_time;
			}
			else
			{
				last_time = "0";
			}
	
			if (!_channel)
			{
				channel = parameters.realtime_channel;
			}
			else
			{
				channel = _channel;
			}
			if (!_subscriber)
			{
				subscriber_id = parameters.realtime_subscriber;
			}
			else
			{
				subscriber_id = _subscriber;
			}
			
			ExternalInterface.addCallback("realtimeUnloadWindow",unloadRealtime);
			connect();
		}
		
		public function unloadRealtime():void
		{
			logger("Unload Realtime");
			if (timer && timer.running)
			{
				timer.stop();
				loader.load(new URLRequest(
					"/realtime/channels/" + channel +
					"/remove_subscriber?ver=2&subscriber_id=" + base64encode(subscriber_id)));
			}
		}
		
		///////////////////////////////////////
		//The following are functions to over-ride
		////////////////////////////////////////
		
			protected function onDataLoad(data:String):void
			{
				logger("Realtime Data:")
				logger(data)
				onXMLLoad(XML(data));
			}

			protected function onXMLLoad(data:XML):void
			{
			}
			
			protected function logger(str:String):void
			{
				trace(str);
			}

			protected function addSubscriber(subsriber:String):void
			{
			}
			
			protected function removeSubscriber(subscriber:String):void
			{
			}

			protected function updateSubscribers(subscribers:String):void
			{
			}

			protected function setConnectionMethod(meth:String):void
			{
				connectStatus = meth;	
			}
			
		private function connect():void
		{
			cancelSocket = false;
			socket= new XMLSocket();
//			socket.addEventListener(Event.CONNECT, onConnect);
//			socket.addEventListener(DataEvent.DATA, onData);
//			socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
//			socket.addEventListener(Event.CLOSE, onDisconnect);
//			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			addSocketListeners();

			socket.connect(parameters.realtime_host, parameters.realtime_port);
			timeoutTimer = new Timer(2000);
			timeoutTimer.addEventListener(TimerEvent.TIMER, socketTimeoutTimer);
			timeoutTimer.start();
			
		}
		
		private function socketTimeoutTimer(event:Event):void
		{
			timeoutTimer.stop();
			if (!socket.connected)
			{
				logger("No SOCKET! Start polling!!");
				cancelSocket = true;
				startPolling();
			}
		}
		

		private function onData(event:DataEvent):void
		{
			if (!cancelSocket)
			{
				var parts:Array=event.data.split("\n");
				var data:Object = new Object();
				for (var i:int = 0; i<parts.length; i++)
				{
					var bits:Array = parts[i].split(": ");
					data[bits[0]] = unescape(bits[1].replace(/\+/g, ' '));
				}
			
				if (subscribing)
				{
					subscribing=false
					if (data['action'] == "SUB_OK")
					{
						if (subscriber_id == 'none')
						{
							subscriber_id=data['data'];
						}
						logger('Subscribed with subscriber_id' + subscriber_id);
						refreshTimer=new Timer(10000);
						refreshTimer.addEventListener(TimerEvent.TIMER, refreshSubscriber);
						refreshTimer.start();
					}
					else
					{
						logger('Error subscribing to socket!');
						startPolling();
					}
				}
				else if (data['action'] == 'SYS_SUBS')
				{
					logger('sys_subs');
					updateSubscriberList(data['data'].split(','));
				}
				else
				{
					logger("SET REALTIME 1");
					last_time = data['last_time'];
					onDataLoad(data['data']);
				}
				logger(event.data);
			}
		}

		private function onConnect(success:Boolean):void
		{
			if (success && !cancelSocket)
			{trace("RealtimeService::onConnect()::success=true");
				subscribe();
			}
			else
			{trace("RealtimeService::onConnect()::success=flase");
				startPolling();
			}
		}

		protected function startPolling():void
		{
trace("RealtimeService::startPolling(): timer=" + timer);
if (timer != null)
{
trace("RealtimeService::startPolling(): timer.running=" + timer.running);
}
//			if (socket != null)
//			{trace("RealtimeService::startPolling(): calling removeSocketListeners()");
//				removeSocketListeners();
//			}
			if (timer == null || !timer.running)	// avoid starting multiple timers
			{
				trace("RealtimeService::startPolling()");
				if (refreshTimer)
				{
					refreshTimer.stop();
				}
				//Initialize the last time
				
				loader.addEventListener(Event.COMPLETE, onHTTPLoad);
				loader.dataFormat=URLLoaderDataFormat.TEXT;
	
				timer = new Timer(2000);
				timer.addEventListener(TimerEvent.TIMER, doPoll);
				timer.start();
				setConnectionMethod('polling');
			}
		}
		
		protected function stopPolling():void
		{
			trace("RealtimeService::stopPolling()");
			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER, doPoll);
//			if (socket != null)
//			{trace("RealtimeService::stopPolling(): calling removeSocketListeners()");
//				removeSocketListeners();
//			}
			setConnectionMethod("disconnected");
		}

		private function doPoll(event:Event):void
		{
			loader.load(new URLRequest(generatePollUrl()));
		}

		private function onHTTPLoad(event:Event):void
		{
			if (event.target.data != null && event.target.data != "unload")
			{
				var data:URLVariables=new URLVariables(event.target.data.toString());
				subscriber_id = data.subscriber_id;
				last_time = data.last_time;
				if (data.new_message == 'yes')
				{
					var parts:Array=data.msgs.split("====IDP_BREAK====");
					for (var i:int = 0; i<parts.length; i++)
					{
						onDataLoad(parts[i]);
					}
					logger("Pulled:" + data.msgs);
				}
				else
				{
					// logger("Pulled Nothing" + data.subscribers);
				}
				updateSubscriberList(data.subscribers.split(','));
			}
			else
			{
				logger("Error with Pull!");
			}
		}

		protected function disconnect():void
		{
			trace("RealtimeService::disconnect()");
			socket.close();
		}

		private function onIOError(event:Event):void
		{	
			trace("RealtimeService::onIOError:event= " + event);
			startPolling();
		}

		private function subscribe():void
		{
			subscribing=true;
			setConnectionMethod('socket');
			var str:String = "action: subscribe\ndata: " + unescape(channel) + "\nsubscriber_id: " + subscriber_id + "\nlast_time: " + last_time + "\n"; 
			socket.send(str);
		}


		private function onDisconnect(event:Event):void
		{trace("RealtimeService::onDisconnect():event= " + event);
			logger("disconnected");
			setConnectionMethod('disconnected');
			startPolling();
		}

		private function refreshSubscriber(event:Event):void
		{
			socket.send("action: refresh_subscribers\n")
		}

		private function updateSubscriberList(subscribers:Array):void
		{
			var newSubscribers:Array = new Array;
			var removedSubscribers:Array = new Array;
			var i:Number;
			// newSubscribers = subscribers;
			newSubscribers = subArray(subscribers, subscriberList);
			if (newSubscribers.length > 0)
			{
				//logger("Add subscriber" + newSubscribers.join(', '));
			}
			for (i=0; i < newSubscribers.length; i++)
			{
				addSubscriber(newSubscribers[i]);
			}

			removedSubscribers = subArray(subscriberList, subscribers);
			if (removedSubscribers.length > 0)
			{
				// logger("Removed Subscribers:" + removedSubscribers.join(', '));
			}
			for (i=0; i < removedSubscribers.length; i++)
			{
				removeSubscriber(removedSubscribers[i]);
			}

			subscriberList = new Array;
			for (i=0; i < subscribers.length; i++)
			{
				subscriberList.push(subscribers[i]);
			}
			updateSubscribers(subscribers.join(", "));
		}

		private function generatePollUrl():String
		{
			var url:String = ""
			url = "/realtime/channels/" + channel;
			// logger(subscriber_id + '@' + url);
			url = url + "?last_time=" + last_time;
			
			if (!(subscriber_id == 'none'))
			{
				url = url + "&ver=2&subscriber_id=" + base64encode(subscriber_id);
			}
			return url;
		}



		private function onSecurityError(event:SecurityErrorEvent):void
		{
			logger("RealtimeService::onSecurityError: " + event);
			trace("RealtimeService::onSecurityError(): connectStatus=" + connectStatus )
			if (connectStatus != "disconnected")
			{
				startPolling();
			}
		}
		
		private function subArray(arr1:Array, arr2:Array):Array
		{
			var obj:Object = {};
			var arr:Array = new Array;
			
			for (var i:Number=0; i< arr1.length; i++)
			{
				var exists:Boolean = false;
				for (var n:Number=0; n<arr2.length; n++)
				{
					if (arr2[n]==arr1[i])
					{
						exists = true;
					}
				}
				if (!exists)
				{
					arr.push(arr1[i]);
				}
			}
	        return arr;
	    }
	
		private function base64encode(str:String):String
		{
			var encoder:Base64Encoder = new Base64Encoder();  
			encoder.insertNewLines = false;  
			encoder.encode(str);
			return encoder.toString();
		}
/*
	    private function removeSocketListeners():void
	    {trace("RealtimeService::removeSocketListeners()");
			if (socket.hasEventListener(Event.CONNECT))
			{
				socket.removeEventListener(Event.CONNECT, onConnect);
				trace("socket.removeEventListener(Event.CONNECT, onConnect);");
			}
			if (socket.hasEventListener(DataEvent.DATA))
			{
				socket.removeEventListener(DataEvent.DATA, onData);
				trace("socket.removeEventListener(DataEvent.DATA, onData);");
			}
			if (socket.hasEventListener(IOErrorEvent.IO_ERROR))
			{
				socket.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
				trace("socket.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);");
			}
			if (socket.hasEventListener(Event.CLOSE))
			{
				socket.removeEventListener(Event.CLOSE, onDisconnect);
				trace("socket.removeEventListener(Event.CLOSE, onDisconnect);");
			}
			if (socket.hasEventListener(SecurityErrorEvent.SECURITY_ERROR))
			{
				socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				trace("socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);");
			}
	    }
*/	    
	    private function addSocketListeners():void
	    {trace("RealtimeService::addSocketListeners()");
			if (!socket.hasEventListener(Event.CONNECT))
			{
				socket.addEventListener(Event.CONNECT, onConnect);
				trace("socket.addEventListener(Event.CONNECT, onConnect);");
			}
			if (!socket.hasEventListener(DataEvent.DATA))
			{
				socket.addEventListener(DataEvent.DATA, onData);
				trace("socket.addEventListener(DataEvent.DATA, onData);");
			}
			if (!socket.hasEventListener(IOErrorEvent.IO_ERROR))
			{
				socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
				trace("socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);");
			}
			if (!socket.hasEventListener(Event.CLOSE))
			{
				socket.addEventListener(Event.CLOSE, onDisconnect);
				trace("socket.addEventListener(Event.CLOSE, onDisconnect);");
			}
			if (!socket.hasEventListener(SecurityErrorEvent.SECURITY_ERROR))
			{
				socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
				trace("socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);");
			}
	    }

	}
}