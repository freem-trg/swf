﻿package format.swf.data.actions.swf7
{
	import format.swf.data.actions.*;
	
	class ActionThrow extends Action implements IAction
	{
		public static inline var CODE:Int = 0x2a;
		
		public function ActionThrow(code:Int, length:Int) {
			super(code, length);
		}
		
		override public function toString(indent:Int = 0):String {
			return "[ActionThrow]";
		}
	}
}
