declare namespace getSideChannel {
	type Key = unknown;
	type ListNode<T> = {
		key: Key;
		next: ListNode<T>;
		value: T;
	};
	type RootNode<T> = {
		key: object;
		next: null | ListNode<T>;
	};
	function listGetNode<T>(list: RootNode<T>, key: ListNode<T>['key']): ListNode<T> | void;
	function listGet<T>(objects: RootNode<T>, key: ListNode<T>['key']): T | void;
	function listSet<T>(objects: RootNode<T>, key: ListNode<T>['key'], value: T): void;
	function listHas<T>(objects: RootNode<T>, key: ListNode<T>['key']): boolean;

	type Channel = {
		assert: (key: Key) => void;
		has: (key: Key) => boolean;
		get: <T>(key: Key) => T;
		set: <T>(key: Key, value: T) => void;
	}
}

declare function getSideChannel(): getSideChannel.Channel;

export = getSideChannel;
